// doxia-greeter --setup: "Preparando sua conta", the screen of an account's
// first login. doxia-mango-session runs it in a bare mango before the session
// while lib/setup-user seeds the account (a few minutes: Node.js, Java, the
// icons, Chrome, Claude Code, the Whisper model), so signing in goes on from
// the login screen to this one instead of to a black screen. The landscape and
// the clock stay; the sign-in becomes the step, a bar and its percentage.
//
// The bar follows setup-user's "==> " steps, each weighted by how long it
// usually takes, and creeps inside the current one so it never sits still.
// Everything setup-user prints also goes to ~/.local/state/doxia/setup.log.

use crate::{accounts, data_dir};
use doxia_login::landscape;
use gtk::prelude::*;
use gtk::{gdk, gio, glib};
use gtk4_layer_shell::{Edge, KeyboardMode, Layer, LayerShell};
use std::cell::{Cell, RefCell};
use std::io::Write;
use std::rc::Rc;
use std::time::{Duration, Instant};

const SETUP: &str = "/usr/share/doxia/lib/setup-user";

// setup-user's steps in order: how its title starts, what the screen says and
// about how many seconds it takes on a fresh account.
const STEPS: &[(&str, &str, f64)] = &[
  ("Seeding DoxIA configs", "Copiando as configurações", 1.0),
  ("DoxIA branding", "Aplicando a marca do DoxIA", 1.0),
  ("DoxIA bar", "Montando a barra", 1.0),
  ("Menu extensions", "Configurando o menu", 1.0),
  ("nvm and SDKMAN!", "Instalando o Node.js e o Java", 56.0),
  ("zsh with Oh My Zsh", "Configurando o terminal", 3.0),
  ("nano as the default editor", "Configurando o editor de texto", 1.0),
  ("uwsm session environment", "Preparando a sessão", 1.0),
  ("Fonts", "Instalando as fontes", 3.0),
  ("GTK apps", "Pintando os ícones e os aplicativos", 52.0),
  ("Theme", "Aplicando o tema", 2.0),
  ("XCompose", "Configurando o teclado", 1.0),
  ("Google Chrome", "Configurando o Google Chrome", 9.0),
  ("Claude Code", "Instalando o Claude Code", 34.0),
  ("Voxtype", "Baixando o modelo de ditado por voz", 54.0),
];

struct Panel {
  step: gtk::Label,
  detail: gtk::Label,
  bar: gtk::ProgressBar,
  percent: gtk::Label,
  status: gtk::Label,
  done: gtk::Button,
}

struct Setup {
  main_loop: glib::MainLoop,
  windowed: bool,
  sky: Rc<Cell<Option<landscape::Sky>>>,
  windows: RefCell<Vec<gtk::Window>>,
  panel: RefCell<Option<Panel>>,
  // The step running (an index into STEPS) and since when.
  current: Cell<Option<usize>>,
  since: Cell<Instant>,
  fraction: Cell<f64>,
  finished: Cell<bool>,
  ok: Cell<bool>,
}

fn total() -> f64 {
  STEPS.iter().map(|s| s.2).sum()
}

impl Setup {
  fn build(self: &Rc<Self>) {
    for w in self.windows.borrow_mut().drain(..) {
      w.destroy();
    }
    let Some(display) = gdk::Display::default() else { return };
    let monitors: Vec<gdk::Monitor> =
      display.monitors().iter::<glib::Object>().filter_map(|m| m.ok()?.downcast::<gdk::Monitor>().ok()).collect();
    if self.windowed || monitors.is_empty() {
      let first = monitors.first();
      let window = self.window(first, true);
      if let (Some(m), Some(child)) = (first, window.child()) {
        child.set_size_request(m.geometry().width(), m.geometry().height());
      }
      window.present();
      self.windows.borrow_mut().push(window);
    } else {
      for (i, monitor) in monitors.iter().enumerate() {
        let window = self.window(Some(monitor), i == 0);
        window.init_layer_shell();
        window.set_namespace(Some("doxia-setup"));
        window.set_layer(Layer::Top);
        window.set_monitor(Some(monitor));
        window.set_exclusive_zone(-1);
        window.set_keyboard_mode(if i == 0 { KeyboardMode::OnDemand } else { KeyboardMode::None });
        for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
          window.set_anchor(edge, true);
        }
        window.present();
        self.windows.borrow_mut().push(window);
      }
    }
    self.render();
  }

  fn window(self: &Rc<Self>, monitor: Option<&gdk::Monitor>, with_panel: bool) -> gtk::Window {
    let window = gtk::Window::builder().decorated(false).title("DoxIA").build();
    window.add_css_class("login-window");
    let sky = self.sky.clone();
    let area = doxia_login::landscape_area(move || sky.get(), || false);
    let backdrop = doxia_login::backdrop(monitor, &data_dir().join("brand.png"), area);
    window.set_child(Some(&backdrop.overlay));
    if with_panel {
      backdrop.overlay.add_overlay(&self.panel(backdrop.height));
    }
    window
  }

  // Where the sign-in was: the account, "Preparando sua conta", the step, the
  // bar and a note; on a failure, what to do and a button to go on.
  fn panel(self: &Rc<Self>, height: f64) -> gtk::Box {
    let column = doxia_login::sign_in(height);
    column.set_size_request(460, -1);
    let me = std::env::var("USER").unwrap_or_default();
    let user = accounts::users().into_iter().find(|u| u.name == me);
    let shown = user.as_ref().map(|u| u.shown().to_string()).unwrap_or(me);
    column.append(&doxia_login::avatar(&shown, user.as_ref().and_then(|u| u.face.as_deref())));
    column.append(&doxia_login::label("Preparando sua conta", &["login-name"]));

    let step = doxia_login::label("", &["login-step"]);
    step.set_ellipsize(gtk::pango::EllipsizeMode::End);
    column.append(&step);

    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    let bar = gtk::ProgressBar::new();
    bar.add_css_class("login-progress");
    bar.set_hexpand(true);
    bar.set_valign(gtk::Align::Center);
    row.append(&bar);
    let percent = doxia_login::label("0%", &["login-percent"]);
    percent.set_width_chars(4);
    percent.set_xalign(1.0);
    row.append(&percent);
    column.append(&row);

    let detail = doxia_login::label(" ", &["login-detail"]);
    detail.set_ellipsize(gtk::pango::EllipsizeMode::End);
    column.append(&detail);

    let status = doxia_login::label(
      "Isso acontece só no primeiro acesso e leva alguns minutos. Não desligue o computador.",
      &["login-note"],
    );
    status.set_wrap(true);
    status.set_max_width_chars(56);
    status.set_justify(gtk::Justification::Center);
    column.append(&status);

    let done = gtk::Button::with_label("Continuar");
    done.add_css_class("login-power");
    done.set_halign(gtk::Align::Center);
    done.set_cursor_from_name(Some("pointer"));
    done.set_visible(false);
    let l = self.main_loop.clone();
    done.connect_clicked(move |_| l.quit());
    column.append(&done);

    *self.panel.borrow_mut() = Some(Panel { step, detail, bar, percent, status, done });
    column
  }

  fn render(&self) {
    let guard = self.panel.borrow();
    let Some(p) = guard.as_ref() else { return };
    let fraction = self.fraction.get();
    p.bar.set_fraction(fraction);
    p.percent.set_text(&format!("{}%", (fraction * 100.0).floor() as i32));
    if self.finished.get() && !self.ok.get() {
      p.step.set_text("A configuração não terminou");
      p.status.set_text(
        "Você já pode usar o DoxIA; o que faltou é tentado de novo no próximo acesso. \
         Os detalhes estão em ~/.local/state/doxia/setup.log.",
      );
      p.status.add_css_class("failed");
      p.done.set_visible(true);
      p.done.grab_focus();
      return;
    }
    let text = match self.current.get() {
      _ if self.finished.get() => "Pronto",
      Some(i) => STEPS[i].1,
      None => "Começando",
    };
    let n = self.current.get().map(|i| i + 1).unwrap_or(0);
    p.step.set_text(&if n > 0 && !self.finished.get() { format!("{text} · passo {n} de {}", STEPS.len()) } else { text.to_string() });
  }

  fn detail(&self, text: &str) {
    if let Some(p) = self.panel.borrow().as_ref() {
      p.detail.set_text(text);
    }
  }

  // A "==> " line: the step it names starts (a step that never prints, like
  // an optional download already done, is simply passed over).
  fn line(&self, line: &str) {
    if let Some(title) = line.strip_prefix("==> ") {
      if let Some(i) = STEPS.iter().position(|s| title.starts_with(s.0)) {
        self.current.set(Some(i));
        self.since.set(Instant::now());
        self.detail(" ");
        self.render();
      }
      return;
    }
    // The sub-steps setup-user indents ("  Node.js LTS"), not tool chatter.
    let trimmed = line.trim();
    if line.starts_with("  ") && !trimmed.is_empty() && trimmed.len() < 70 && trimmed.chars().next().is_some_and(char::is_alphanumeric) {
      self.detail(trimmed);
    }
  }

  fn tick(&self) {
    let Some(i) = self.current.get() else { return };
    let before: f64 = STEPS[..i].iter().map(|s| s.2).sum();
    let weight = STEPS[i].2;
    let inside = (self.since.get().elapsed().as_secs_f64() / weight).min(0.9) * weight;
    let fraction = ((before + inside) / total()).min(0.99);
    if fraction > self.fraction.get() {
      self.fraction.set(fraction);
      self.render();
    }
  }

  fn finish(self: &Rc<Self>, ok: bool) {
    self.finished.set(true);
    self.ok.set(ok);
    if ok {
      self.fraction.set(1.0);
      self.detail(" ");
    }
    self.render();
    if ok {
      let l = self.main_loop.clone();
      glib::timeout_add_local_once(Duration::from_millis(900), move || l.quit());
    }
  }

  fn start(self: &Rc<Self>) {
    let command = std::env::var("DOXIA_SETUP_COMMAND").unwrap_or_else(|_| SETUP.into());
    let mut file = std::env::var_os("HOME").and_then(|home| {
      let dir = std::path::Path::new(&home).join(".local/state/doxia");
      let _ = std::fs::create_dir_all(&dir);
      std::fs::OpenOptions::new().create(true).append(true).open(dir.join("setup.log")).ok()
    });
    let process = match gio::Subprocess::newv(
      &[std::ffi::OsStr::new(&command)],
      gio::SubprocessFlags::STDOUT_PIPE | gio::SubprocessFlags::STDERR_MERGE,
    ) {
      Ok(p) => p,
      Err(e) => {
        eprintln!("doxia-greeter: {command}: {e}");
        self.finish(false);
        return;
      }
    };
    let me = self.clone();
    glib::spawn_future_local(async move {
      if let Some(out) = process.stdout_pipe() {
        let lines = gio::DataInputStream::new(&out);
        while let Ok(Some(line)) = lines.read_line_utf8_future(glib::Priority::DEFAULT).await {
          if let Some(f) = file.as_mut() {
            let _ = writeln!(f, "{line}");
          }
          me.line(&line);
        }
      }
      let ok = process.wait_check_future().await.is_ok();
      me.finish(ok);
    });
    let weak = Rc::downgrade(self);
    glib::timeout_add_local(Duration::from_millis(200), move || match weak.upgrade() {
      Some(me) if !me.finished.get() => {
        me.tick();
        glib::ControlFlow::Continue
      }
      _ => glib::ControlFlow::Break,
    });
  }
}

// Runs setup-user on its screen; fails when setup-user did.
pub fn run(windowed: bool, sky: Rc<Cell<Option<landscape::Sky>>>, snapshot_to: Option<String>) -> glib::ExitCode {
  let main_loop = glib::MainLoop::new(None, false);
  let setup = Rc::new(Setup {
    main_loop: main_loop.clone(),
    windowed,
    sky,
    windows: RefCell::default(),
    panel: RefCell::default(),
    current: Cell::new(None),
    since: Cell::new(Instant::now()),
    fraction: Cell::new(0.0),
    finished: Cell::new(false),
    ok: Cell::new(false),
  });
  setup.build();
  if let Some(display) = gdk::Display::default() {
    let weak = Rc::downgrade(&setup);
    display.monitors().connect_items_changed(move |_, _, _, _| {
      let weak = weak.clone();
      glib::timeout_add_local_once(Duration::from_millis(300), move || {
        if let Some(me) = weak.upgrade() {
          me.build();
        }
      });
    });
  }
  setup.start();
  if let Some(path) = snapshot_to {
    let weak = Rc::downgrade(&setup);
    let n = Cell::new(0);
    glib::timeout_add_local(Duration::from_secs(2), move || {
      let Some(me) = weak.upgrade() else { return glib::ControlFlow::Break };
      n.set(n.get() + 1);
      if let Some(w) = me.windows.borrow().first() {
        crate::snapshot(w, &format!("{path}.{}", n.get()));
      }
      glib::ControlFlow::Continue
    });
  }
  main_loop.run();
  if setup.ok.get() { glib::ExitCode::SUCCESS } else { glib::ExitCode::FAILURE }
}

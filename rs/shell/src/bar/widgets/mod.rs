// The widgets a layout entry can name. An id the bar does not know yet
// takes no space.

mod agents;
mod audio;
mod bluetooth;
mod calendar;
pub mod clock;
mod doxia;
mod fortivpn;
mod group;
mod indicators;
mod media;
mod monitor;
mod network;
mod network_model;
mod notifications;
mod power;
mod services;
mod system;
mod tray;
mod usage;
mod weather;
mod weather_model;

pub use weather::current_condition as weather_now;

use super::config::entry_id;
use super::member::Member;
use gtk::prelude::*;
use super::Ctx;
use serde_json::Value;
use std::rc::Rc;

pub fn build(ctx: &Rc<Ctx>, entry: &Value) -> Option<gtk::Widget> {
  match entry_id(entry).as_str() {
    "doxia.clock" => Some(clock::build(ctx, entry)),
    "doxia.emblem" => Some(doxia::emblem(ctx)),
    "doxia.workspaces" => Some(doxia::workspaces(ctx)),
    "doxia.screenshare" => Some(doxia::screenshare(ctx)),
    "doxia.usage" => usage::build(ctx, entry),
    "doxia.media" => Some(media::build(ctx, entry)),
    "doxia.weather" => Some(weather::build(ctx, entry)),
    // The tray's menus are not panels the keys open.
    "doxia.tray" => {
      let place = ctx.current.borrow_mut().take();
      let w = tray::build(ctx, entry);
      *ctx.current.borrow_mut() = place;
      Some(w)
    }
    "doxia.services" => Some(services::build(ctx)),
    "doxia.fortivpn" => Some(fortivpn::build(ctx, entry)),
    "doxia.agents" => Some(agents::build(ctx, entry)),
    "doxia.indicators" => Some(indicators::build(ctx, entry)),
    "doxia.notifications" => notifications::build(ctx),
    "doxia.menu" => Some(system::menu_button(ctx)),
    "doxia.workspaces" => Some(system::doxia_workspaces(ctx)),
    "doxia.keyboard-layout" => Some(system::keyboard_layout(ctx)),
    "doxia.system-update" => Some(system::system_update(ctx)),
    id @ ("doxia.audio" | "doxia.power" | "doxia.monitor" | "doxia.network" | "doxia.bluetooth") => member(ctx, id, entry).map(Member::standalone),
    "doxia.group" => group::build(ctx, entry, |id, e| member(ctx, id, e)),
    _ => None,
  }
}

// A widget with a panel, alone on the bar or in a group: listed under its
// own id, at the place of its entry (a group's members share the group's).
fn member(ctx: &Rc<Ctx>, id: &str, entry: &Value) -> Option<Member> {
  let place = ctx.current.borrow_mut().take();
  let m = make_member(ctx, id, entry);
  *ctx.current.borrow_mut() = place.clone();
  if let (Some(m), Some((_, region, order)), Some(bar)) = (m.as_ref(), place, ctx.bar.upgrade()) {
    let w = m.button.widget.downgrade();
    bar.register(super::Handle {
      id: id.to_string(),
      region,
      order,
      monitor: ctx.monitor.clone(),
      panel: Rc::downgrade(&m.panel),
      visible: Rc::new(move || w.upgrade().is_some_and(|w| w.is_visible())),
    });
  }
  m
}

fn make_member(ctx: &Rc<Ctx>, id: &str, entry: &Value) -> Option<Member> {
  match id {
    "doxia.audio" => Some(audio::build(ctx)),
    "doxia.power" => Some(power::build(ctx, entry)),
    "doxia.monitor" => Some(monitor::build(ctx)),
    "doxia.network" => Some(network::build(ctx)),
    "doxia.bluetooth" => Some(bluetooth::build(ctx)),
    _ => None,
  }
}

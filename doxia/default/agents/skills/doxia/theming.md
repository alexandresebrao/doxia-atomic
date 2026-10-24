# Themes, Backgrounds, and Fonts

Read this before changing themes, backgrounds, fonts, or theme colors.

## Theme Commands

```bash
doxia theme list              # Show available themes
doxia theme current           # Show current theme
doxia theme set <name>        # Apply theme ("Tokyo Night" and "tokyo-night" both work)
doxia theme bg next           # Cycle background
doxia theme install <url>     # Install from git repo
```

## Making a New Theme

1. Create a directory under `~/.config/doxia/themes`.
2. See how an existing theme is done via `/usr/share/doxia/themes/catppuccin`.
3. Download a matching background (or several) from the internet and put them in `~/.config/doxia/themes/<name-of-new-theme>/backgrounds/`.
4. When done with the theme, run `doxia theme set "Name of new theme"`.

Additional user backgrounds for any theme (stock or custom) go in
`~/.config/doxia/backgrounds/<theme-slug>/`.

## What a Theme Installed From a Repo May Not Contain

A theme the user wrote by hand in `~/.config/doxia/themes` is unrestricted, as
are DoxIA's own themes. From a theme cloned by `doxia theme install`, DoxIA
drops only what runs code: any `*.lua` (Neovim loads `neovim.lua` at startup),
the terminal configs `alacritty.toml`, `foot.ini`, `ghostty.conf` and
`kitty.conf` (each names the program the terminal launches), `mango.conf` and
`mango-looknfeel.conf` (mango runs their `exec=` lines and spawn binds), and
`vscode.json` (names a VS Code extension to install). Those are regenerated from `colors.toml`
through `$DOXIA_PATH/default/themed/*.tpl`, and named on stderr.

Everything else a cloned theme ships is kept, including `btop.theme`,
`chromium.theme`, `helix.toml`, `icons.theme`, `keyboard.rgb` and `shell.toml`.
DoxIA tells a cloned theme from the user's own by the `.git` directory a clone
leaves behind.

To change how DoxIA themes an app for every theme, write the template rather
than the theme: `~/.config/doxia/themed/<config-name>.tpl` overrides the
built-in one. See `docs/theming.md` in the DoxIA repo.

## Customizing a Stock Theme

Never edit stock themes under `/usr/share/doxia/themes/` — changes are lost
on update. Two safe options:

Both write into `~/.config/doxia/themes`, where a theme the user wrote is
unrestricted — the list above applies only to a theme cloned from a repo.

**Overlay (preferred for small tweaks):** create a user theme directory with
the SAME slug containing only the files you want to change. When the theme is
applied, the stock theme is copied first and your files win on top:

```bash
mkdir -p ~/.config/doxia/themes/catppuccin
cp /usr/share/doxia/themes/catppuccin/colors.toml ~/.config/doxia/themes/catppuccin/
# Edit the copied colors.toml, then re-apply:
doxia theme set catppuccin
```

**Fork:** copy the whole stock theme under a new name for a fully independent
variant:

```bash
cp -r /usr/share/doxia/themes/catppuccin ~/.config/doxia/themes/catppuccin-custom
# Edit ~/.config/doxia/themes/catppuccin-custom/, then:
doxia theme set catppuccin-custom
```

## Fonts

```bash
doxia font list               # Available fonts
doxia font current            # Current font
doxia font set <name>         # Change font
```

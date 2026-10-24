# DoxIA Shell: Bar, Widgets, and Idle

Read this before changing the status bar, notifications, widgets, or
idle/lock behavior.

The bar, notifications, OSD, menus, pickers, lock screen, and idle timers all
run inside one long-running process, `doxia-shell` (Rust + GTK 4, the user
unit `doxia-shell.service`; source in `$DOXIA_PATH/lib/rs/shell`).
Its widgets are built in: there are no shell plugins to add, clone, or edit.

```
~/.config/doxia/shell.json             # User overrides: bar, idle
$DOXIA_PATH/config/doxia/shell.json  # Canonical defaults
```

doxia-shell rereads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `doxia restart shell`, `doxia refresh shell`

## Bar Layout

Use the `doxia bar` group to place, move, and configure widgets:

```bash
doxia bar move doxia.clock --section right
doxia bar put doxia.keyboard-layout --after doxia.clock
doxia bar remove doxia.keyboard-layout
doxia bar set doxia.clock format HH:mm
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/doxia/shell.json`; it reloads on save.

## Idle and Lock

Set `idle.screensaver` and `idle.lock` in `~/.config/doxia/shell.json`,
in seconds since user idle began. Example: "lock after ten minutes" means
setting `idle.lock` to `600`.

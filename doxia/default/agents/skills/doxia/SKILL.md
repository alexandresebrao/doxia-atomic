---
name: doxia
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/mango/, ~/.config/doxia/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or ~/.config/ghostty/.
  Triggers: mango, window rules, animations, keybindings, monitors, gaps, borders,
  blur, opacity, doxia-shell-call, bar, terminal config, themes, background,
  night light, idle, lock screen, screenshots, reminders, layer rules, workspace
  settings, display config, and user-facing doxia commands. Excludes DoxIA
  source development through `doxia dev link` workflows.
---

# DoxIA Skill

Manage [DoxIA](https://github.com/alexandresebrao/doxia-atomic) Linux systems - a beautiful, modern, opinionated Linux distribution. DoxIA runs it on Fedora with the mango compositor.

This skill is for end-user customization on installed systems.
It is not for contributing to DoxIA source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/mango/` (window rules, animations, keybindings, monitors, etc.)
- Editing `~/.config/doxia/shell.json` (status bar layout, widgets)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/doxia/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `doxia` commands (`doxia theme ...`, `doxia refresh ...`, `doxia restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for DoxIA development tasks** (editing the DoxIA source tree, creating migrations, or running `doxia dev ...` workflows).

## Topic Guides

Deeper instructions for common areas live next to this file. Read the
matching guide before starting:

- [`mango.md`](mango.md) - keybindings, monitors, window rules, and other mango config
- [`plugins.md`](plugins.md) - the DoxIA shell: bar layout, widgets, idle behavior
- [`theming.md`](theming.md) - themes, backgrounds, and fonts
- [`hooks.md`](hooks.md) - automation hooks that run on system events
- [`capture.md`](capture.md) - screenshots, screen recordings, OCR text capture, and file sharing
- [`contributing.md`](contributing.md) - reporting DoxIA bugs and submitting fixes upstream

## Critical Safety Rules

For privileged commands, follow the Privilege Escalation rules below: `sudo` when a terminal is available for the password prompt, `pkexec` when it is not. Do not wrap commands that already manage privilege elevation themselves.

**For end-user customization tasks, NEVER modify anything in `/usr/share/doxia/`** - but READING is safe and encouraged.

This directory is owned by the doxia package. Any local changes will be
overwritten on the next `doxia update`.

```
/usr/share/doxia/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Command source (packaged binaries are on PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── shell/                  # DoxIA shell source and defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `/usr/share/doxia/` is SAFE and useful** - do it freely to:
- Understand how doxia commands work: `doxia theme set --help` or `cat $(which doxia-theme-set)`
- See default configs before customizing: `cat "$DOXIA_PATH/config/doxia/shell.json"`
- Check stock theme files to copy for customization
- Reference default mango settings: `cat /usr/share/doxia/default/mango/*.conf`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/doxia/themes/<custom-name>/` - Custom themes
- `~/.config/doxia/hooks/` - Custom automation hooks

If the request is to develop DoxIA itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## Privilege Escalation

For an interactive script or command run in a visible terminal, use `sudo` for
privileged work. DoxIA may grant passwordless `sudo` access to particular
commands, and the terminal is the appropriate place to request a password
when one is needed.

Use `pkexec` only when the caller cannot interact with a terminal or cannot
enter a password there, such as a command launched by an agent or a graphical
background process. Do not replace `sudo` with `pkexec` merely because a
command changes system state.

## System Architecture

DoxIA is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Fedora** | Base OS | `/etc/`, `~/.config/` |
| **mango** | Wayland compositor/WM | `~/.config/mango/` |
| **DoxIA shell** | Status bar + notifications (doxia-shell) | `~/.config/doxia/shell.json` |
| **Launcher/menus** | doxia-shell menu | `~/.config/doxia/extensions/doxia-menu.jsonc` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **DoxIA OSD** | On-screen display | doxia-shell |

## Command Discovery

DoxIA ships a single `doxia` CLI that dispatches to all `doxia-*` binaries via `doxia <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `doxia-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary (--all includes hidden commands)
doxia commands

# Show the commands inside a group
doxia theme --help
doxia refresh --help
doxia restart --help

# Show help for a specific command (does not execute it)
doxia theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
doxia commands --json

# Read a command's source to understand it
cat $(which doxia-theme-set)
```

### Command Groups

Run `doxia --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `doxia refresh` | Reset config to defaults (backs up first) | `doxia refresh shell` |
| `doxia restart` | Restart a service/app | `doxia restart shell` |
| `doxia toggle` | Toggle feature on/off | `doxia toggle nightlight` |
| `doxia theme` | Theme management | `doxia theme set <name>` |
| `doxia bar` | Bar layout and widgets | `doxia bar move doxia.clock --section right` |
| `doxia hook` | Install automation hooks | `doxia hook install theme-set <script>` |
| `doxia install` | Install optional software / packages | `doxia install docker dbs` |
| `doxia launch` | Launch apps | `doxia launch browser` |
| `doxia capture` | Screenshots and recordings | `doxia capture screenshot` |
| `doxia reminder` | Desktop notification reminders | `doxia reminder 15 "Pickup Jack"` |
| `doxia pkg` | Package management | `doxia pkg add <pkg>` |
| `doxia setup` | Interactive setup wizards | `doxia setup security fingerprint` |
| `doxia update` | System updates | `doxia update` |

## Configuration Locations

mango config lives in `~/.config/mango/` — see [`mango.md`](mango.md).
The DoxIA shell (bar, notifications, idle) is configured in
`~/.config/doxia/shell.json` — see [`plugins.md`](plugins.md).

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `doxia restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `/etc/fastfetch/config.jsonc` default; `~/.config/fastfetch/config.jsonc` user override |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/mango/bindings.conf

# 2. Backup before changes
cp ~/.config/mango/bindings.conf ~/.config/mango/bindings.conf.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - mango: MUST validate with `mango -p`, then apply with `doxia restart mango`
# - DoxIA shell: shell.json reloads on save
# - Menus/launcher: ~/.config/doxia/extensions/doxia-menu.jsonc hot-reloads on save
# - Terminals: apply with `doxia restart terminal` (reloads running terminals; foot picks changes up in new windows)
```

### Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
doxia refresh shell
doxia refresh mango

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from $DOXIA_PATH/config/
# 3. Restarts the component where the refresh needs it (e.g. `refresh shell`)
```

## System Commands

```bash
doxia update                  # Full system update
doxia version                 # Show DoxIA version
doxia debug --no-sudo --print # Debug info (ALWAYS use these flags)
doxia system lock             # Lock screen
doxia system shutdown         # Shutdown
doxia system reboot           # Reboot
```

**IMPORTANT:** Always run `doxia debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
doxia debug --no-sudo --print

# Reset specific config to defaults
doxia refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `doxia refresh config mango/config.conf` will refresh ~/.config/mango/config.conf
doxia refresh config <config-file>

# Full reinstall of configs (nuclear option)
doxia reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock doxia command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `/usr/share/doxia/`
3. **Is it a theme customization?** Follow [`theming.md`](theming.md); create a NEW custom theme directory
4. **Is it automation?** Follow [`hooks.md`](hooks.md); use `doxia hook install` and the hook `.d` directories
5. **Is it a package install?** Use `doxia pkg add <pkgs...>` (or `doxia pkg aur add <pkgs...>` for AUR-only packages)
6. **Is it the bar or idle?** Follow [`plugins.md`](plugins.md); use `doxia bar` or edit shell.json, never the packaged code
7. **Unsure if command exists?** Run `doxia commands` (or `doxia <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `doxia reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
doxia reminder 15 "Pickup Jack"
doxia reminder 60 "Check laundry"
doxia reminder show
doxia reminder clear
```

## Out of Scope

This skill intentionally does not cover DoxIA source development. Do not use this skill for:
- Editing files in `/usr/share/doxia/` (`bin/`, `config/`, `default/`, `shell/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `doxia dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `doxia theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, then add a `bind=` in `~/.config/mango/bindings.conf` (it replaces an DoxIA bind on the same key)
- "Configure my external monitor" -> Edit `~/.config/mango/monitors.conf`
- "Make the window gaps smaller" -> Edit `~/.config/mango/looknfeel.conf`
- "Turn on night light" -> `doxia toggle nightlight`
- "Set a reminder to pickup jack in 15 minutes" -> `doxia reminder 15 "Pickup Jack"`
- "Show my reminders" -> `doxia reminder show`
- "Clear all reminders" -> `doxia reminder clear`
- "Customize the catppuccin theme colors" -> Overlay: put an edited `colors.toml` in `~/.config/doxia/themes/catppuccin/`, then re-apply the theme (see `theming.md`)
- "Run a script every time I change themes" -> Install it with `doxia hook install theme-set <script>`
- "Change how workspace labels are rendered" -> Clone `doxia.workspaces`, which switches the bar to `<username>.workspaces`, then edit the clone
- "Lock after ten minutes" -> Set `idle.lock` to `600` in `~/.config/doxia/shell.json`
- "Reset shell/bar to defaults" -> `doxia refresh shell`
- "Record my screen" -> `doxia screenrecord --fullscreen`, then `doxia screenrecord --stop-recording` (see `capture.md`)
- "Report this bug to DoxIA" -> Gather diagnostics and a capture of the problem, then file it (see `contributing.md`)

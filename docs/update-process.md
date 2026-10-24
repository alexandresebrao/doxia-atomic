# DoxIA update process

This document describes the intended update behavior now that DoxIA is
package-backed. It covers the blessed update path plus what happens when a user attempts to
bypass it:

1. `doxia update` — the blessed interactive DoxIA update flow.
2. `sudo pacman -Syu` — guarded by DoxIA and aborted with instructions unless
   the user explicitly bypasses the guard.

The design goal is:

- `doxia update` owns the visible update pipeline: package transaction,
  migrations, post-update hooks, update-state refresh, and restart checks.
- Migrations run per-user after pacman finishes, because they may need `$HOME`,
  DBus/session state, a graphical session, sudo, or user interaction.
- Users who bypass `doxia update` are nudged back by the pacman guard; if they
  explicitly bypass it, their session is notified when migrations are pending.

## State and coordination files

| Path | Owner | Purpose |
| --- | --- | --- |
| `${XDG_RUNTIME_DIR:-/tmp}/doxia-update.lock` | user | Prevent overlapping update runs. Owned by `doxia-update-lock`; compatibility wrappers inherit/respect it. |
| `/tmp/doxia-update.log` | user | Transcript of `doxia update`, used by `doxia-update-analyze-logs`. |
| `~/.local/state/doxia/current/` | user | Generated active theme, selected theme name, and current background symlink. |
| `~/.local/state/doxia/migrations/` | user | Per-user migration markers. |
| `~/.local/state/doxia/reboot-required` | user | Optional reboot marker checked by `doxia-update-restart`. |
| `~/.local/state/doxia/restart-*-required` | user | Optional service/app restart markers checked by `doxia-update-restart`. The shell needs no marker: it is restarted unconditionally after every update. |

## Migration layout

See [`migrations.md`](migrations.md) for the full migration model, authoring
guidelines, and troubleshooting notes.

Migrations live in:

```text
migrations/*.sh
```

They run as the current user through:

```bash
doxia-migrate
```

Completion state is per-user:

```text
~/.local/state/doxia/migrations/<migration filename>
```

Every user gets a chance to run every migration. Migrations run as the user;
privileged work should invoke the appropriate helper or privilege prompt.
Migrations must be idempotent; if one user already applied a machine-wide repair,
the migration should no-op for other users.

For watchers and diagnostics, `doxia-migrate --pending` prints pending
migration names and exits `0` when any are pending. When no migrations are
pending, it prints nothing and exits non-zero.

## Raw pacman guard

The `doxia` package installs an ALPM pre-transaction hook alongside its guard
binary:

```text
/usr/share/libalpm/hooks/00-doxia-update-guard.hook
/usr/bin/doxia-update-pacman-guard
```

It triggers on package upgrades and runs:

```bash
doxia-update-pacman-guard
```

The guard detects direct pacman system-upgrade commands like `pacman -Syu` or
`pacman --sync --refresh --sysupgrade`. If the upgrade was not launched by an
DoxIA update command, the hook exits non-zero with `AbortOnFail`, which stops
the transaction before packages are changed.

`doxia-update-system-pkgs`, `doxia-refresh-pacman`, `doxia-reinstall-pkgs`,
and the v4 upgrader run pacman through:

```bash
env DOXIA_UPDATE_PACMAN=1 pacman ...
```

so the guard allows DoxIA-owned update flows. A user can intentionally bypass
the guard with:

```bash
sudo env DOXIA_ALLOW_DIRECT_PACMAN=1 pacman -Syu
```

The guard does not start `doxia update` itself because pacman is already in a
transaction setup path; it only aborts with instructions.

## Path 1: `doxia update`

High-level flow:

```text
doxia-update
  ├─ ensure transcript logging through script(1) → /tmp/doxia-update.log
  ├─ doxia-update-lock
  │    └─ acquire the update lock and run doxia-update inside it
  ├─ doxia-update-requires-free-space
  │    └─ check free space on / and warn below the configured threshold
  ├─ confirm unless -y
  ├─ create snapper snapshot, if snapper is installed
  ├─ doxia-update-stay-awake start
  ├─ run package updates, migrations, hooks, and log analysis
  ├─ doxia-update-status
  │    └─ refresh or clear the shell update indicator
  ├─ doxia-update-stay-awake stop
  │    └─ release the sleep inhibitor and restore shell idle state, if changed
  └─ doxia-update-restart
```

Important behavior:

- In dev-link mode, `doxia update` fast-forwards the active checkout from its
  configured upstream before changing system packages or running migrations.
- The free-space requirement uses a 10 GiB threshold and stops the update before
  confirmation when it is not met. If free space cannot be determined, the
  check is silently skipped. Set `DOXIA_UPDATE_FORCE=1` to bypass the check.
- `doxia update` checks/runs migrations in the same visible terminal via
  `doxia-migrate` after pacman finishes.
- A failure should leave enough output in `/tmp/doxia-update.log` and the
  terminal transcript to debug.

## Path 2: direct `sudo pacman -Syu` attempt

High-level flow:

```text
sudo pacman -Syu
  ├─ pre-transaction guard aborts and tells the user to run doxia update
  └─ if explicitly bypassed, upgrades doxia and related packages
  └─ at that user's next login
       ├─ graphical-session.target starts
       ├─ doxia-migrate-notify.service starts after it
       ├─ doxia-migrate-notify checks doxia-migrate --pending
       ├─ if this user has missing migration state, show notification
       └─ click opens terminal: doxia-migrate
```

Login is deliberately the only trigger. A watcher on the packaged migration
directory cannot distinguish a bypassed `pacman -Syu` from the package
transaction inside a normal `doxia update`, so it fired notifications for
migrations that `doxia-migrate` was about to apply in the visible update
terminal. The retired unit was `doxia-update-user-notify.path`.

Retiring that watcher through a migration cannot come in time for the update
that retires it: pacman writes the migration directory, the watcher fires, and
only then does `doxia-migrate` reach the migration that stops it. So the
notifier also refuses to run while `doxia update` holds its
`$XDG_RUNTIME_DIR/doxia-update.lock`, which covers the stale watcher and any
trigger added later — during an update, every pending migration is by
definition already being applied a step away. It checks again after waiting for
the notification server, since that wait is long enough for an update to start
underneath it.

The notifier reads only its own user's runtime directory, never the `/tmp` path
`doxia-update` falls back to when `XDG_RUNTIME_DIR` is unset. A shared lock
file belongs to whoever created it first, so honouring it would let one user
silence another user's notification. Missing an update and showing a redundant
toast is the better failure.

Suppression is why `doxia-update-stay-awake` starts its sleep inhibitor with
the lock descriptor closed. That inhibitor outlives the step that starts it, so
an update killed before cleanup would otherwise leave it holding the flock
indefinitely — blocking later updates and, now that the notifier reads the same
lock, silencing migration notifications at every login.

Fallbacks:

- `doxia-provision-first-run` enables `doxia-migrate-notify.service`, which also
  covers users created after install: their per-user migration markers are
  missing, so their first login prompts them to run every shipped migration.
- The package ships `doxia-update-user-notify.service` as a symlink onto
  `doxia-migrate-notify.service`. Users set up before the rename hold an
  absolute `graphical-session.target.wants` symlink to the old path, and the
  migration that repoints it only runs for users who run an update — the
  opposite of who the notifier is for. The alias can be dropped once installs
  have run migration `1785095882`.
- The notifier is ordered after `graphical-session.target`, so an action that
  launches through `uwsm-app` cannot block the target that gates UWSM's app
  daemon.
- The notifier waits for a live notification server before sending, because
  `graphical-session.target` can be reached before the shell claims
  `org.freedesktop.Notifications`.
- The notifier is only a prompt. It does not run migrations in the background.
- A session that is already open when another user updates is not re-checked;
  it picks the migrations up at its next login, or whenever that user runs
  `doxia-migrate` or `doxia update`.
- Direct pacman updates do not run `doxia-hook post-update` unless the user
  explicitly runs that hook; without a package-update marker, the only pending
  state we can derive is missing per-user migration markers.

## Shell update indicator and the Atualizar DoxIA window

Fedora port. `doxia-update-check` lists what an update would change, as JSON:
dnf packages (installed and new versions), Flatpak apps and runtimes, new
commits for the dev-linked checkout, and an update downloaded and waiting for
the reboot. It keeps a copy in `~/.cache/doxia/update-status.json` and exits
`0` when there is something to do. `doxia-update-available` keeps the old
one-line-per-source output on top of it.

The bar widget `doxia.system-update` runs the check on shell startup and every
`checkHours` (preference, default 6). Its popup summarizes the state and opens
the window; it also runs the background Flatpak update (`autoFlatpak`) and sends
the notification when an update finishes.

The window is `doxia-atualizar`, a GTK 4 app in Rust (`fedora/doxia/rs/atualizar`,
installed from a release by `fedora/doxia/install-rs`), opened by
`doxia-launch-update` (Menu > Atualizar > DoxIA, and the bar popup). It runs
outside the shell because the "Configuração do DoxIA" step (`fedora/update.sh`)
reloads the shell, which closed the window when it was the `doxia.update`
panel plugin; that panel is still the fallback without the app. It shows
each source and when it installs, the password prompt with every command the
update runs as root, the progress, the result, and the preferences
(`doxia-update-pref`, stored in `~/.config/doxia/update.json`):

| Key | Default | Meaning |
| --- | --- | --- |
| `mode` | `boot` | `boot`: system packages download now and install on the next reboot. `now`: installed right away. |
| `autoremoveOrphans` | `true` | `dnf autoremove -y` at the end, without asking. |
| `snapshot` | `true` | Snapper snapshot before updating (ignored without Snapper). |
| `checkHours` | `6` | How often the bar checks. |
| `autoFlatpak` | `false` | Update Flatpak apps in the background. |

### How the window runs an update

`doxia-update-run start <now|boot|flatpak>` starts `doxia-update --gui` in
the transient user unit `doxia-update-run.service`, so the run survives a
shell restart. `doxia-update` still runs under `script(1)`, which gives sudo
a terminal: `sudo -A -v` asks once through `doxia-update-askpass` (the window
writes the answer into a FIFO, never argv) and the usual keepalive covers the
rest. Each step is recorded with `doxia-update-state`:

| Path | Purpose |
| --- | --- |
| `$XDG_RUNTIME_DIR/doxia-update/state.json` | The run in progress: steps, progress, password prompt. |
| `~/.local/state/doxia/update-last.json` | The last finished run (or boot finish); `seen` / `notified` flags. |

`--flatpak` needs no password: polkit lets the active user update system-wide
Flatpak apps.

### Installing on the next reboot

With `mode` = `boot`, Flatpak, mise and new DoxIA commits apply right away, and
`doxia-update-system-pkgs --offline` runs `dnf upgrade --offline`, which
downloads and tests the transaction. `doxia-update-offline arm` (root) then
prepares it the way `dnf5 offline reboot` does (the `/system-update` link and
the `ready` status) without rebooting, so the next reboot or poweroff installs
it in `system-update.target`, with the boot splash in its "updates" mode. It
also installs `doxia-update-finish.service`, which on the following boot, before
any login, runs the migrations, the post-update hook and the orphan cleanup
(`fedora/doxia/update-finish`, like `first-boot-update`) and writes the result
for the window. When dnf has nothing to download, the rest applies right away
and no reboot is needed. `doxia-update-run cancel-staged` (pkexec) drops a
waiting update.

## Update-related binaries

This inventory is intentionally opinionated. Some commands are useful as stable
leaf commands; others exist mostly because the old update flow accreted small
scripts.

| Binary | Current purpose | Keep? / Question |
| --- | --- | --- |
| `doxia-update` | Public user command. Adds transcript logging, confirmation, snapshot, and restart checks around the locked, sleep-inhibited update pipeline. | **Keep.** This is the blessed entry point and orchestrates the update pipeline. |
| `doxia-update-lock` | Hidden command wrapper that holds the per-user update lock while its child runs. | **Keep internal/hidden.** Isolates update concurrency and lock descriptor handling. |
| `doxia-update-stay-awake` | Hidden helper that starts or stops update-owned sleep and idle inhibition, restoring only the state it changed. | **Keep internal/hidden.** Keeps inhibitor ownership and cleanup together. |
| `doxia-update-status` | Hidden helper that refreshes or clears the shell update indicator after rechecking available updates. | **Keep internal/hidden.** Keeps shell status synchronization out of the main pipeline. |
| `doxia-update-confirm` | Gum confirmation copy for `doxia update`. | **Question.** Could be inlined into `doxia-update`; separate file only helps keep copy isolated. |
| `doxia-update-dev` | Fast-forwards the active dev-linked checkout from its configured upstream; no-ops for package-backed installs. | **Keep.** Runs before package updates so a checkout conflict stops the update before system mutation. |
| `doxia-update-keyring` | Ensures DoxIA keyring and Arch keyring are current before the main transaction. | **Keep, but review.** It uses targeted `pacman -Sy` for keyring bootstrapping; acceptable for this special case but should remain tightly scoped. |
| `doxia-update-system-pkgs` | Runs `sudo env DOXIA_UPDATE_PACMAN=1 pacman -Syu --noconfirm` with targeted transition `--overwrite` entries so the ALPM guard allows the transaction and early package-layout conflicts are handled. | **Keep for now.** Small leaf command, clear/testable. |
| `doxia-migrate` | Public migration command. Waits for pacman, then runs all pending migrations for the current user. Supports `--pending`. | **Keep.** This replaces the discarded `doxia-update-user-finalize` name and no longer needs `--force`. |
| `doxia-update-pacman-guard` | ALPM pre-transaction guard that aborts direct `pacman -Syu` style upgrades unless DoxIA set `DOXIA_UPDATE_PACMAN=1` or the user explicitly set `DOXIA_ALLOW_DIRECT_PACMAN=1`. | **Keep internal/hidden.** This is what nudges users back to `doxia update`. |
| `doxia-migrate-notify` | Internal login-time notification helper. Uses `doxia-migrate --pending` and shows a notification only when this user has pending migrations. | **Keep internal/hidden.** Clear name now that the public command is `doxia-migrate`. |
| `doxia-update-user-notify` | Hidden compatibility wrapper for `doxia-migrate-notify`. | **Temporary.** Keep only for old callers. |
| `doxia-update-available` | Update checker for shell widget and post-update refresh. | **Keep.** Could eventually be renamed `doxia-update-check`, but current name matches widget semantics. |
| `doxia-update-aur-pkgs` | Updates AUR packages with `yay -Sua` if foreign packages exist and AUR is reachable. | **Question.** DoxIA is package-backed now, but users may still install AUR packages. Keep for now. |
| `doxia-update-mise` | Runs `mise up` for mise-managed tools. | **Keep.** Mise-managed tools are intentionally part of the blessed update path. |
| `doxia-update-orphan-pkgs` | Lists orphans and prompts before removal; noninteractive mode never removes. | **Keep for now.** Safe because it is prompt-only. |
| `doxia-update-analyze-logs` | Scans `/tmp/doxia-update.log` for known failure patterns, currently initramfs generation. | **Keep/expand.** Useful safety net; should grow only for high-signal checks. |
| `doxia-update-restart` | Prompts for reboot after kernel/mango updates, restarts components with `restart-*-required` markers, and always restarts the shell. | **Keep.** Important final step; may eventually include service-restart checks. |
| `doxia-update-firmware` | Manual firmware update command using fwupd. Not part of the normal update pipeline. | **Keep separate.** Firmware is not a routine system update step. |
| `doxia-update-time` | Restarts `systemd-timesyncd`. | **Question.** Not really an update command. Consider renaming/moving under system/time maintenance. |

## Closed decisions

1. **Migrations run per-user from the update pipeline**
   - `doxia update` runs `doxia-migrate` after pacman finishes.
   - Package-time migration runners do not apply migrations inside pacman.
   - Every user has per-user migration markers, and migrations must be
     idempotent when they repair machine-wide state.

2. **Migration notification naming**
   - The real helper is `doxia-migrate-notify`, started by
     `doxia-migrate-notify.service`.
   - `doxia-update-user-notify` remains only as a hidden compatibility wrapper.

3. **Update pipeline ownership**
   - `doxia-update` owns the full update pipeline now.

4. **Mise remains in the blessed update path**
   - `doxia-update-mise` intentionally runs as part of `doxia update`.

5. **Orphan cleanup stays in the update path for now**
   - It is prompt-only and never removes packages noninteractively.

6. **Direct pacman user follow-up is based on actual migration state**
   - Direct `sudo pacman -Syu` no longer uses a fake user-update marker.
   - User notifications are shown only when `doxia-migrate --pending` finds
     missing per-user migration state.

## Remaining concerns

1. **Pacman guard scope**
   - The guard detects direct pacman sysupgrade invocations and allows DoxIA
     commands that set `DOXIA_UPDATE_PACMAN=1`.
   - We may regret blocking some legitimate package-manager frontends or
     maintenance flows. Keep an eye on what should be allowed versus redirected
     to `doxia update`.

2. **Pacnew/pacsave handling is still missing**
   - Package-backed DoxIA should warn about or help process `.pacnew` and
     `.pacsave` files after updates.

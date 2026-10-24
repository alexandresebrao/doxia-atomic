#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/bin"
SYSTEMCTL_LOG="$TMPDIR/systemctl-log"

cat >"$TMPDIR/bin/systemctl" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$SYSTEMCTL_LOG"
SH

cat >"$TMPDIR/bin/doxia-notification-send" <<'SH'
#!/bin/bash
exit 0
SH

chmod +x "$TMPDIR/bin/systemctl" "$TMPDIR/bin/doxia-notification-send"

test_home="$TMPDIR/home"
flag="$test_home/.local/state/doxia/toggles/crash-capture-off"

toggle_crash_capture() {
  PATH="$TMPDIR/bin:$ROOT/bin:$PATH" \
  SYSTEMCTL_LOG="$SYSTEMCTL_LOG" \
  HOME="$test_home" \
    "$ROOT/bin/doxia-toggle-crash-capture"
}

toggle_crash_capture
[[ -f $flag ]] || fail "crash capture toggle disables the watcher"
grep -Fqx -- "--user stop doxia-crash-watch.service" "$SYSTEMCTL_LOG" ||
  fail "crash capture toggle stops the running watcher, so disabling takes effect before the next login"
pass "crash capture toggle disables the watcher"

: >"$SYSTEMCTL_LOG"
toggle_crash_capture
[[ ! -f $flag ]] || fail "crash capture toggle re-enables the watcher"
grep -Fqx -- "--user start doxia-crash-watch.service" "$SYSTEMCTL_LOG" ||
  fail "crash capture toggle starts the watcher, so enabling takes effect before the next login"
pass "crash capture toggle re-enables the watcher"

service="$ROOT/default/systemd/user/doxia-crash-watch.service"
grep -Fx 'ConditionPathExists=!%h/.local/state/doxia/toggles/crash-capture-off' "$service" >/dev/null ||
  fail "the watcher is pulled back in at every login, so disabling it never survives a logout"
pass "crash watcher stays disabled across logins"

grep -F 'doxia-crash-watch' "$ROOT/fedora/doxia/install-user-units" >/dev/null ||
  fail "crash capture is no longer on by default for new installs"
pass "crash capture is on by default"

grep -F '"trigger.toggle.crash-capture":' "$ROOT/default/doxia/doxia-menu.jsonc" | grep -F '"action":"doxia-toggle-crash-capture"' >/dev/null ||
  fail "menu toggles crash capture from Trigger > Toggle"
pass "menu toggles crash capture from Trigger > Toggle"

#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

# Every step doxia-update runs, recorded in order with the unattended flag it
# was handed. One of them can be told to fail.
steps=(
  doxia-update-lock
  doxia-update-requires-free-space
  doxia-update-confirm
  doxia-update-pkg-prune
  doxia-snapshot
  doxia-update-stay-awake
  doxia-update-dev
  doxia-update-keyring
  doxia-update-system-pkgs
  doxia-migrate
  doxia-hook
  doxia-update-aur-pkgs
  doxia-update-mise
  doxia-update-orphan-pkgs
  doxia-update-analyze-logs
  doxia-update-status
  doxia-update-restart
  doxia-update-check
)

for step in "${steps[@]}"; do
  cat >"$stub_bin/$step" <<'STUB'
#!/bin/bash
# The package count and pending migrations are queries for the summary, not steps.
[[ ${0##*/} == "doxia-update-check" || ${1:-} == "--pending" ]] && exit 0
printf '%s unattended=%s\n' "${0##*/}" "${DOXIA_UPDATE_UNATTENDED:-}" >>"$STEP_LOG"
[[ ${FAILING_STEP:-} != "${0##*/}" ]] || exit 1
STUB
  chmod +x "$stub_bin/$step"
done

# The password is asked once up front and kept fresh while the update runs. The
# update snapshots only where Snapper is installed, and doxia-snapshot is the
# stub above, so this one only has to be found.
for command in sudo snapper; do
  printf '#!/bin/bash\nexit 0\n' >"$stub_bin/$command"
  chmod +x "$stub_bin/$command"
done

# DOXIA_UPDATE_LOGGED stands in for the script(1) wrapper the update re-execs
# itself under; the stubbed lock reports itself already held. --now installs the
# packages in this run: --boot stages them for dnf's offline update and reads
# its state from the live system. XDG_CONFIG_HOME keeps the person's own update
# preferences out of it.
run_update() {
  : >"$test_tmp/steps"
  STEP_LOG="$test_tmp/steps" \
    FAILING_STEP="${FAILING_STEP:-}" \
    DOXIA_UPDATE_LOGGED=1 \
    DOXIA_PATH="$test_tmp/doxia" \
    XDG_CONFIG_HOME="$test_tmp/config" \
    PATH="$stub_bin:$PATH" \
    bash "$ROOT/bin/doxia-update" --now "$@" >"$test_tmp/out" 2>"$test_tmp/err"
}

steps_run() {
  cut -d' ' -f1 "$test_tmp/steps"
}

# Every step of a whole update, in order. $1 asks for the one a person confirms.
# Stay Awake bookends the work, so it is here twice.
expected_steps() {
  printf '%s\n' \
    doxia-update-lock \
    doxia-update-requires-free-space \
    ${1:+doxia-update-confirm} \
    doxia-update-pkg-prune \
    doxia-snapshot \
    doxia-update-stay-awake \
    doxia-update-dev \
    doxia-update-keyring \
    doxia-update-system-pkgs \
    doxia-migrate \
    doxia-hook \
    doxia-update-aur-pkgs \
    doxia-update-mise \
    doxia-update-orphan-pkgs \
    doxia-update-analyze-logs \
    doxia-update-status \
    doxia-update-stay-awake \
    doxia-update-restart
}

run_update -y || fail "an update where everything works reports a failure"
diff <(expected_steps) <(steps_run) >"$test_tmp/order" ||
  fail "an update where everything works does not run every step in order" "$(cat "$test_tmp/order")"
pass "an update where every step works runs all of them, in order"

grep -q '^doxia-update-system-pkgs unattended=1$' "$test_tmp/steps" ||
  fail "-y does not mark the update unattended"
run_update </dev/null || fail "a confirmed update reports a failure"
diff <(expected_steps confirmed) <(steps_run) >"$test_tmp/order" ||
  fail "a confirmed update runs a different set of steps" "$(cat "$test_tmp/order")"
grep -q '^doxia-update-system-pkgs unattended=$' "$test_tmp/steps" ||
  fail "an update a person confirmed is treated as unattended"
pass "-y is what marks an update unattended, not the update itself"

# Migrations ship with the packages the upgrade installs and are written against
# them. Running them against what is still on disk is the failure this ordering
# exists to prevent, so the update stops where the packages did.
if FAILING_STEP=doxia-update-system-pkgs run_update -y; then
  fail "an update whose packages did not upgrade passes for a whole one"
fi
for step in doxia-migrate doxia-hook doxia-update-aur-pkgs doxia-update-restart; do
  if grep -q "^$step " "$test_tmp/steps"; then
    fail "a blocked package upgrade still runs $step"
  fi
done
pass "a blocked package upgrade stops the update before it migrates"

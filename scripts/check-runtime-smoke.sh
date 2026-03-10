#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/runtime_warning_budget.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/runtime_warning_budget.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF2'
Usage:
  scripts/check-runtime-smoke.sh [--boot current|previous] [--allow-non-graphical] [--strict-backends] [--strict-logs] [--skip-log-budget]

Scope:
  Local predator desktop runtime smoke check. This script is intentionally
  scoped to the canonical desktop host and is not a generic multi-host
  smoke runner.

Environment:
  RUNTIME_SMOKE_PORTAL_PIDNS_WARN_MAX=<n>   # override L101 max from warning budget file
  RUNTIME_SMOKE_PORTAL_INHIBIT_WARN_MAX=<n> # override L102 max from warning budget file
  RUNTIME_SMOKE_WPSTATE_WARN_MAX=<n>        # override L103 max from warning budget file
  RUNTIME_SMOKE_GKR_WARN_MAX=<n>            # override L104 max from warning budget file
  RUNTIME_SMOKE_NM_P2P_WARN_MAX=<n>         # override L105 max from warning budget file
EOF2
}

boot="current"
allow_non_graphical=0
strict_backends=0
strict_logs=0
skip_log_budget=0
warning_overruns=0
# shellcheck disable=SC2034
budget_expired=0
scope="runtime-smoke"
config_host="predator"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --boot)
      boot="${2:-}"
      shift 2
      ;;
    --allow-non-graphical)
      allow_non_graphical=1
      shift
      ;;
    --strict-backends)
      strict_backends=1
      shift
      ;;
    --strict-logs)
      strict_logs=1
      shift
      ;;
    --skip-log-budget)
      skip_log_budget=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_fail "$scope" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

ok() {
  log_ok "$scope" "$1"
}

warn() {
  log_warn "$scope" "$1"
}

fail() {
  log_fail "$scope" "$1"
  exit 1
}

require_system_unit_active() {
  local unit="$1"
  if systemctl is-active --quiet "$unit"; then
    ok "system unit active: $unit"
  else
    fail "system unit not active: $unit"
  fi
}

require_user_unit_active() {
  local unit="$1"
  if systemctl --user is-active --quiet "$unit"; then
    ok "user unit active: $unit"
  else
    fail "user unit not active: $unit"
  fi
}

expect_user_unit_active() {
  local unit="$1"
  if systemctl --user is-active --quiet "$unit"; then
    ok "user unit active: $unit"
    return 0
  fi

  if [ "$strict_backends" -eq 1 ]; then
    fail "expected backend user unit not active: $unit"
  fi
  warn "expected backend user unit not active: $unit"
}

require_user_unit_enabled() {
  local unit="$1"
  if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
    ok "user unit enabled: $unit"
  else
    fail "user unit not enabled: $unit"
  fi
}

if [ "$(id -u)" -eq 0 ]; then
  fail "run as regular user so user services can be checked"
fi

if ! [ -f /etc/os-release ] || ! grep -q '^ID=nixos$' /etc/os-release; then
  fail "this smoke check must run on a NixOS host"
fi

require_cmds "$scope" "jq" "rg"

local_host="$(hostname -s 2>/dev/null || hostname)"
if [ "$local_host" != "$config_host" ]; then
  fail "runtime smoke is scoped to ${config_host}; current host is ${local_host}"
fi

case "${boot}" in
  current|previous) ;;
  *)
    fail "invalid --boot value: ${boot} (use current|previous)"
    ;;
esac

require_system_unit_active "greetd.service"

if [ "$allow_non_graphical" -eq 0 ]; then
  case "${XDG_SESSION_TYPE:-}" in
    wayland|x11)
      ok "graphical session type detected: ${XDG_SESSION_TYPE}"
      ;;
    *)
      fail "no graphical session detected (set --allow-non-graphical to bypass)"
      ;;
  esac
else
  warn "non-graphical session allowed by flag"
fi

if [ -n "${XDG_SESSION_ID:-}" ]; then
  if [ "$(loginctl show-session "$XDG_SESSION_ID" -p Active --value 2>/dev/null || echo no)" = "yes" ]; then
    ok "session is active: ${XDG_SESSION_ID}"
  else
    warn "could not confirm active state for session: ${XDG_SESSION_ID}"
  fi
else
  warn "XDG_SESSION_ID is unset"
fi

host_role="$(nix eval --raw "path:$PWD#nixosConfigurations.${config_host}.config.custom.host.role")"
if [ "$host_role" != "desktop" ]; then
  fail "runtime smoke expects desktop host role for ${config_host}, got: ${host_role}"
fi

niri_enabled="$(nix eval --json "path:$PWD#nixosConfigurations.${config_host}.config.programs.niri.enable" | jq -r '.')"
dms_enabled="$(nix eval --json --impure --expr "let cfg = (builtins.getFlake \"path:${PWD}\").nixosConfigurations.${config_host}.config; in builtins.hasAttr \"dsearch\" cfg.systemd.user.services" | jq -r '.')"
keyrs_enabled="$(nix eval --json "path:$PWD#nixosConfigurations.${config_host}.config.services.keyrs.enable" | jq -r '.')"

ok "config host=${config_host} features: niri=${niri_enabled} dms=${dms_enabled} keyrs=${keyrs_enabled}"

if command -v gdbus >/dev/null 2>&1; then
  if gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
    ok "portal DBus ping succeeded"
  else
    fail "portal DBus ping failed"
  fi
else
  warn "gdbus not available; skipping portal ping"
fi

require_user_unit_active "xdg-desktop-portal.service"
expect_user_unit_active "xdg-desktop-portal-gtk.service"

if [ "$niri_enabled" = "true" ]; then
  expect_user_unit_active "xdg-desktop-portal-gnome.service"
fi

if [ "$keyrs_enabled" = "true" ]; then
  require_user_unit_enabled "keyrs.service"
fi

if [ "$dms_enabled" = "true" ]; then
  require_user_unit_enabled "awww-daemon.service"
  require_user_unit_enabled "dms-awww.service"
fi

tmp_log="$(mktemp_file_scoped runtime-smoke-log)"
trap 'rm -f "$tmp_log"' EXIT

set +e
journalctl -b --no-pager >"$tmp_log" 2>/dev/null
sys_code=$?
journalctl --user -b --no-pager >>"$tmp_log" 2>/dev/null
usr_code=$?
set -e

if [ "$sys_code" -ne 0 ] && [ "$usr_code" -ne 0 ]; then
  fail "could not read system or user journal"
fi

if [ "$skip_log_budget" -eq 0 ]; then
  budget_file="$PWD/config/validation/runtime-warning-budget.json"
  if ! runtime_warning_budget_scan "$scope" "$budget_file" "$tmp_log" "$strict_logs" warning_overruns budget_expired; then
    if [ "$strict_logs" -eq 1 ]; then
      fail "runtime warning budget check failed"
    fi
    warning_overruns=1
  fi
else
  warn "log budget checks skipped by flag"
fi

if systemctl --failed --no-pager --legend=0 | grep -q .; then
  fail "system has failed units"
fi

if systemctl --user --failed --no-pager --legend=0 | grep -q .; then
  fail "user session has failed units"
fi

if [ "$warning_overruns" -eq 1 ]; then
  warn "known warning budget overruns detected: 2"
fi

ok "runtime smoke passed"

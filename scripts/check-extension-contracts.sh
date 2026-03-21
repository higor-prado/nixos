#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/set_ops.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/set_ops.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
# shellcheck source=lib/extension_contracts_checks.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/extension_contracts_checks.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

usage() {
  cat <<'EOF2'
Usage:
  scripts/check-extension-contracts.sh

Description:
  Validates host/composition extension contracts and schema invariants.
EOF2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_fail "extension-contracts" "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

report_fail() {
  log_fail "extension-contracts" "$1"
  fail=1
}

require_cmds "extension-contracts" "find" "jq" "nix" "rg"

legacy_desktop_selector_pattern='^[[:space:]]*custom\.desktop\.'
legacy_desktop_selector_pattern+='profile[[:space:]]*='
legacy_host_selector_field="desktop""Profile"
legacy_modules_root="modules/pro""files"
legacy_desktop_selector_dir="${legacy_modules_root}/desktop"

if rg -n --glob '*.nix' "$legacy_desktop_selector_pattern" hardware modules flake.nix >/dev/null; then
  report_fail "legacy desktop selector assignment must not exist after desktop feature-owned cutover"
fi

if rg -n --fixed-strings "$legacy_host_selector_field" scripts/new-host-skeleton.sh >/dev/null; then
  report_fail "legacy desktop selector field usage must be removed from host generator output"
fi

if [[ -e modules/options/desktop-options.nix ]]; then
  report_fail "modules/options/desktop-options.nix must be removed after desktop host-composition cutover"
fi

if [[ -e modules/options/desktop-capabilities-options.nix ]]; then
  report_fail "modules/options/desktop-capabilities-options.nix must be removed after desktop host-composition cutover"
fi

if [[ -e "${legacy_modules_root}/default.nix" || -d "$legacy_desktop_selector_dir" || -e "${legacy_modules_root}/profile-capabilities.nix" ]]; then
  report_fail "legacy desktop selector layer must be removed after desktop host-composition cutover"
fi

# Legacy stub removed — the old tracked private-home path no longer exists.

mapfile -t host_dirs < <(
  find hardware -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -u
)
mapfile -t host_modules < <(
  find modules/hosts -mindepth 1 -maxdepth 1 -type f -name '*.nix' -printf '%f\n' \
    | sed 's/\.nix$//' \
    | sort -u
)

tmpdir="$(mktemp_dir_scoped extension-contracts)"
trap 'rm -rf "$tmpdir"' EXIT

mkset "$tmpdir/host_dirs" "${host_dirs[@]}"
mkset "$tmpdir/host_modules" "${host_modules[@]}"
extc_check_set_sync "host directories" "$tmpdir/host_dirs" "host modules" "$tmpdir/host_modules" report_fail

if [[ ! -x scripts/new-host-skeleton.sh ]]; then
  report_fail "scripts/new-host-skeleton.sh must exist and be executable"
fi

extc_check_host_defaults_contracts report_fail host_dirs

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/composition extension contracts hold"

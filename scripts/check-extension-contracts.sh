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
# shellcheck source=lib/extension_contracts_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/extension_contracts_eval.sh"
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

extc_check_assignment_scope "custom.host.role" '^[[:space:]]*custom\.host\.role[[:space:]]*=' extc_is_allowed_host_role_assignment report_fail

legacy_desktop_selector_pattern='^[[:space:]]*custom\.desktop\.'
legacy_desktop_selector_pattern+='profile[[:space:]]*='
legacy_host_selector_field="desktop""Profile"
legacy_modules_root="modules/pro""files"
legacy_desktop_selector_dir="${legacy_modules_root}/desktop"

if rg -n --glob '*.nix' "$legacy_desktop_selector_pattern" hardware modules home flake.nix >/dev/null; then
  report_fail "legacy desktop selector assignment must not exist after desktop feature-owned cutover"
fi

if rg -n --fixed-strings "$legacy_host_selector_field" hardware/host-descriptors.nix scripts/new-host-skeleton.sh >/dev/null; then
  report_fail "legacy desktop selector field usage must be removed from active host wiring"
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

if [[ -e home/base/desktop/pack-registry.nix ]]; then
  report_fail "home/base/desktop/pack-registry.nix must be removed after concrete desktop composition cutover"
fi

mapfile -t host_dirs < <(
  find hardware -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -u
)
mapfile -t host_descriptor_entries < <(extc_host_descriptor_names)

tmpdir="$(mktemp_dir_scoped extension-contracts)"
trap 'rm -rf "$tmpdir"' EXIT

mkset "$tmpdir/host_dirs" "${host_dirs[@]}"
mkset "$tmpdir/host_descriptors" "${host_descriptor_entries[@]}"
extc_check_set_sync "host directories" "$tmpdir/host_dirs" "host descriptor entries" "$tmpdir/host_descriptors" report_fail

if [[ ! -x scripts/new-host-skeleton.sh ]]; then
  report_fail "scripts/new-host-skeleton.sh must exist and be executable"
fi

extc_check_host_descriptor_matches_defaults report_fail host_dirs

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-contracts] ok: host/composition extension contracts hold"

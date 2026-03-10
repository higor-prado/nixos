#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
cd "$REPO_ROOT" || exit 1

scope="run-validation-gates-fixture-test"
tmpdir="$(mktemp_dir_scoped run-validation-gates-fixture-test)"
trap 'rm -rf "$tmpdir"' EXIT

fixtures_scripts_dir="$tmpdir/scripts"
fixtures_bin_dir="$tmpdir/bin"
log_file="$tmpdir/invocations.log"
mkdir -p "$fixtures_scripts_dir" "$fixtures_bin_dir"
touch "$log_file"

make_stub_check() {
  local name="$1"
  cat >"${fixtures_scripts_dir}/${name}" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$(basename "$0")" >>"${INVOCATION_LOG}"
EOF2
  chmod +x "${fixtures_scripts_dir}/${name}"
}

check_scripts=(
  check-desktop-capability-usage.sh
  check-option-declaration-boundary.sh
  check-flake-pattern.sh
  check-extension-contracts.sh
  check-dendritic-host-onboarding-contracts.sh
  check-validation-source-of-truth.sh
  check-docs-drift.sh
  check-config-contracts.sh
  check-desktop-composition-matrix.sh
  check-extension-simulations.sh
)

for script_name in "${check_scripts[@]}"; do
  make_stub_check "$script_name"
done

cat >"${fixtures_bin_dir}/nix" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
printf 'nix %s\n' "$*" >>"${INVOCATION_LOG}"
if [[ "${1:-}" == "eval" && "${2:-}" == "--raw" ]]; then
  printf 'fixture-user\n'
fi
if [[ "${1:-}" == "eval" && "${2:-}" == "--json" ]]; then
  printf '{}\n'
fi
EOF2
chmod +x "${fixtures_bin_dir}/nix"

assert_logged() {
  local expected="$1"
  if ! rg -Fxq "$expected" "$log_file"; then
    log_fail "$scope" "missing expected invocation: $expected"
    log_warn "$scope" "captured invocations:"
    sed -n '1,200p' "$log_file" >&2 || true
    exit 1
  fi
}

run_stage() {
  local stage="$1"
  : >"$log_file"
  PATH="${fixtures_bin_dir}:$PATH" \
    INVOCATION_LOG="$log_file" \
    VALIDATION_GATES_SCRIPTS_DIR="$fixtures_scripts_dir" \
    ./scripts/run-validation-gates.sh "$stage" >/dev/null
}

run_stage "structure"
assert_logged "check-desktop-capability-usage.sh"
assert_logged "check-option-declaration-boundary.sh"
assert_logged "check-flake-pattern.sh"
assert_logged "check-extension-contracts.sh"
assert_logged "check-dendritic-host-onboarding-contracts.sh"
assert_logged "check-validation-source-of-truth.sh"
assert_logged "check-docs-drift.sh"

run_stage "predator"
assert_logged "check-config-contracts.sh"
assert_logged "check-desktop-composition-matrix.sh"
assert_logged "check-extension-simulations.sh"
assert_logged "nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name"
assert_logged "nix flake metadata"
assert_logged "nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion"
assert_logged "nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.fixture-user.home.stateVersion"
assert_logged "nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.fixture-user.home.path"
assert_logged "nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel"

run_stage "aurelius"
assert_logged "nix eval path:$PWD#nixosConfigurations.aurelius.config.custom.host.role"
assert_logged "nix eval path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion"
assert_logged "nix eval path:$PWD#nixosConfigurations.aurelius.pkgs.stdenv.hostPlatform.system"

log_ok "$scope" "fixture-based stage orchestration checks passed"

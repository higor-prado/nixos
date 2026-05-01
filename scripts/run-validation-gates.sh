#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/validation_host_topology.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/validation_host_topology.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"

scripts_dir="${VALIDATION_GATES_SCRIPTS_DIR:-./scripts}"
tests_dir="${VALIDATION_GATES_TESTS_DIR:-./tests/scripts}"

run_check_script() {
	local script_name="$1"
	"${scripts_dir}/${script_name}"
}

run_test_script() {
	local script_name="$1"
	bash "${tests_dir}/${script_name}"
}

run_structure_gates() {
	echo "[validation-gates] structure gates"
	run_check_script "check-bare-host-in-includes.sh"
	run_check_script "check-feature-legacy-role-conditionals.sh"
	run_check_script "check-flake-inputs-used.sh"
	run_check_script "check-desktop-capability-usage.sh"
	run_check_script "check-option-declaration-boundary.sh"
	run_check_script "check-flake-pattern.sh"
	run_check_script "check-extension-contracts.sh"
	run_check_script "check-feature-publisher-name-match.sh"
	run_check_script "check-validation-source-of-truth.sh"
	run_check_script "check-docs-drift.sh"
	run_check_script "check-repo-public-safety.sh"
	run_test_script "run-validation-gates-fixture-test.sh"
	run_test_script "new-host-skeleton-fixture-test.sh"
	run_test_script "report-persistence-candidates-test.sh"
	run_test_script "runtime-warning-budget-lib-test.sh"
}

run_predator_gates() {
	local host
	host="$(validation_stage_host "predator")"
	echo "[validation-gates] predator gates"
	local hm_user
	hm_user="$(nix_eval_sole_hm_user_for_host "$host")"

	run_check_script "check-config-contracts.sh"
	run_check_script "check-desktop-composition-matrix.sh"
	nix flake metadata
	nix eval "path:$PWD#nixosConfigurations.${host}.config.system.stateVersion"
	nix eval "path:$PWD#nixosConfigurations.${host}.config.home-manager.users.${hm_user}.home.stateVersion"
	nix build --no-link "path:$PWD#nixosConfigurations.${host}.config.home-manager.users.${hm_user}.home.path"
	nix build --no-link "path:$PWD#nixosConfigurations.${host}.config.system.build.toplevel"
}

run_aurelius_gates() {
	local host
	host="$(validation_stage_host "aurelius")"
	echo "[validation-gates] aurelius gates"
	nix eval "path:$PWD#nixosConfigurations.${host}.config.system.stateVersion"
	nix eval "path:$PWD#nixosConfigurations.${host}.pkgs.stdenv.hostPlatform.system"
}

run_cerebelo_gates() {
	local host hm_user
	host="$(validation_stage_host "cerebelo")"
	hm_user="$(nix_eval_sole_hm_user_for_host "$host")"
	echo "[validation-gates] cerebelo gates"
	run_check_script "check-config-contracts.sh"
	nix eval "path:$PWD#nixosConfigurations.${host}.config.system.stateVersion"
	nix eval "path:$PWD#nixosConfigurations.${host}.pkgs.stdenv.hostPlatform.system"
	nix eval "path:$PWD#nixosConfigurations.${host}.config.home-manager.users.${hm_user}.home.stateVersion"
}

run_named_host_stage() {
	case "$1" in
	predator)
		run_predator_gates
		;;
	aurelius)
		run_aurelius_gates
		;;
	cerebelo)
		run_cerebelo_gates
		;;
	*)
		echo "[validation-gates] unknown host stage: $1" >&2
		exit 1
		;;
	esac
}

usage() {
	cat <<'EOF2'
Usage: scripts/run-validation-gates.sh [structure|predator|aurelius|cerebelo|all]

Commands:
  structure       Run structure/policy gates only.
  predator        Run predator eval/build gates only.
  aurelius        Run aurelius eval-only gates.
  cerebelo        Run cerebelo eval-only gates.
  all             Run structure + declared host validation stages (default).
EOF2
}

stage="${1:-all}"

case "$stage" in
structure)
	run_structure_gates
	;;
predator)
	run_predator_gates
	;;
aurelius)
	run_aurelius_gates
	;;
cerebelo)
	run_cerebelo_gates
	;;
all)
	run_structure_gates
	while IFS= read -r stage_name; do
		[[ -n "$stage_name" ]] || continue
		run_named_host_stage "$stage_name"
	done < <(validation_host_stages)
	echo "[validation-gates] ok"
	;;
-h | --help | help)
	usage
	;;
*)
	echo "[validation-gates] unknown stage: $stage" >&2
	usage >&2
	exit 1
	;;
esac

#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
cd "$REPO_ROOT" || exit 1

scope="check-flake-pattern-fixture-test"

run_expect() {
 local expected_code="$1"
 local flake_content="$2"
 local label="${3:-}"

 local fixture_dir
 fixture_dir="$(mktemp_dir_scoped "$scope")"
 trap 'rm -rf "$fixture_dir"' RETURN

 # Layout so enter_repo_root resolves to $fixture_dir.
 mkdir -p "$fixture_dir/scripts/lib" "$fixture_dir/modules"
 printf '%s\n' "$flake_content" >"$fixture_dir/flake.nix"
 cp "$REPO_ROOT/scripts/lib/common.sh" "$fixture_dir/scripts/lib/common.sh"
 cp "$REPO_ROOT/scripts/check-flake-pattern.sh" "$fixture_dir/scripts/check-flake-pattern.sh"
 chmod +x "$fixture_dir/scripts/check-flake-pattern.sh"

 # Provide a .nix file with pkgs.stdenv.hostPlatform.system so the accessor
 # consistency check does not fail on an empty tree.
 printf '{ pkgs, ... }: { services.foo.package = pkgs.stdenv.hostPlatform.system; }\n' \
  >"$fixture_dir/modules/dummy.nix"

 local actual_code=0
 (
  cd "$fixture_dir"
  set +e
  bash scripts/check-flake-pattern.sh >/dev/null 2>&1
  exit $?
 ) || actual_code=$?

 if [ "$actual_code" -ne "$expected_code" ]; then
  log_fail "$scope" "[$label] expected exit $expected_code, got $actual_code"
  return 1
 fi
}

# Minimal valid flake.nix — only the inputs block matters for kebab-case checks.
make_flake() {
 local inputs_block="$1"
 cat <<HEAD
{
  description = "test";
  inputs = {
HEAD
 printf '%s\n' "$inputs_block"
 cat <<TAIL
  };
  outputs = { ... }: { };
}
TAIL
}

# ── Test cases ──

# A1: Block-form input with valid kebab-case — should PASS
run_expect 0 \
 "$(make_flake 'my-input = { url = "github:foo/bar"; };')" \
 "A1: block-form valid kebab"

# A2: Block-form input with underscore — should FAIL
run_expect 1 \
 "$(make_flake 'my_input = { url = "github:foo/bar"; };')" \
 "A2: block-form underscore"

# B1: Short-form input with valid kebab-case — should PASS
run_expect 0 \
 "$(make_flake 'my-input.url = "github:foo/bar";')" \
 "B1: short-form valid kebab"

# B2: Short-form input with underscore — should FAIL
run_expect 1 \
 "$(make_flake 'my_input.url = "github:foo/bar";')" \
 "B2: short-form underscore"

# C1: Mix of both forms, all valid — should PASS
run_expect 0 \
 "$(make_flake '
    nixpkgs.url = "github:NixOS/nixpkgs";
    my-input = { url = "github:foo/bar"; };
  ')" \
 "C1: mixed both valid"

# C2: Mix of both forms, one invalid short-form — should FAIL
run_expect 1 \
 "$(make_flake '
    nixpkgs.url = "github:NixOS/nixpkgs";
    bad_input.url = "github:foo/bar";
  ')" \
 "C2: mixed one invalid short-form"

log_ok "$scope" "all fixture checks passed"

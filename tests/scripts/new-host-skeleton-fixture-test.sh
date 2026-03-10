#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

scope="new-host-skeleton-fixture-test"
tmpdir="$(mktemp_dir_scoped new-host-skeleton-fixture-test)"
trap 'rm -rf "$tmpdir"' EXIT

fixture_repo="$tmpdir/repo"
mkdir -p "$fixture_repo/scripts/lib" "$fixture_repo/templates/new-host-skeleton"
cp scripts/new-host-skeleton.sh "$fixture_repo/scripts/"
cp scripts/lib/common.sh "$fixture_repo/scripts/lib/"
cp templates/new-host-skeleton/*.tpl "$fixture_repo/templates/new-host-skeleton/"

(
  cd "$fixture_repo" &&
    bash scripts/new-host-skeleton.sh zeus desktop dms-on-niri >/dev/null &&
    bash scripts/new-host-skeleton.sh ci-runner server >/dev/null
)

diff -u tests/fixtures/new-host-skeleton/desktop/hardware/zeus/default.nix \
  "$fixture_repo/hardware/zeus/default.nix"
diff -u tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix \
  "$fixture_repo/modules/hosts/zeus.nix"
diff -u tests/fixtures/new-host-skeleton/server/hardware/ci-runner/default.nix \
  "$fixture_repo/hardware/ci-runner/default.nix"
diff -u tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix \
  "$fixture_repo/modules/hosts/ci-runner.nix"

log_ok "$scope" "fixture-based generator output checks passed"

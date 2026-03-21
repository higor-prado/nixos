#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

scope="report-persistence-candidates-test"
tmpdir="$(mktemp_dir_scoped "$scope")"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p \
  "$tmpdir/etc/ssh" \
  "$tmpdir/etc/NetworkManager/system-connections" \
  "$tmpdir/var/lib/docker" \
  "$tmpdir/var/lib/systemd" \
  "$tmpdir/var/cache/steam" \
  "$tmpdir/var/tmp/steam" \
  "$tmpdir/root" \
  "$tmpdir/srv" \
  "$tmpdir/opt"

printf 'machine\n' >"$tmpdir/etc/machine-id"
printf 'ssh-key\n' >"$tmpdir/etc/ssh/ssh_host_ed25519_key"
printf 'journal-state\n' >"$tmpdir/var/lib/systemd/state"
printf 'docker-state\n' >"$tmpdir/var/lib/docker/state"
printf 'shader-cache\n' >"$tmpdir/var/cache/steam/state"
printf 'tmp-state\n' >"$tmpdir/var/tmp/steam/state"
printf 'root-state\n' >"$tmpdir/root/state"

cat >"$tmpdir/persisted-paths.nix" <<EOF
{
  directories = [
    "${tmpdir}/etc/NetworkManager/system-connections"
    "${tmpdir}/var/lib/docker"
  ];

  files = [
    "${tmpdir}/etc/machine-id"
    "${tmpdir}/etc/ssh/ssh_host_ed25519_key"
  ];

  ignored = [
    "${tmpdir}/root"
  ];
}
EOF

output_file="$tmpdir/report.out"
PERSISTENCE_DECLARED_PATHS_FILE="$tmpdir/persisted-paths.nix" \
PERSISTENCE_ETC_ROOT="$tmpdir/etc" \
PERSISTENCE_VAR_LIB_ROOT="$tmpdir/var/lib" \
PERSISTENCE_VAR_CACHE_ROOT="$tmpdir/var/cache" \
PERSISTENCE_VAR_TMP_ROOT="$tmpdir/var/tmp" \
PERSISTENCE_ROOT_OWNED_CANDIDATES="$tmpdir/root $tmpdir/srv $tmpdir/opt" \
  bash scripts/report-persistence-candidates.sh predator /persist >"$output_file"

assert_contains() {
  local pattern="$1"
  if ! rg -q --fixed-strings -- "$pattern" "$output_file"; then
    log_fail "$scope" "missing expected pattern: $pattern"
    sed -n '1,220p' "$output_file" >&2
    exit 1
  fi
}

assert_contains "------------------------------------------------------------"
assert_contains "Legend:"
assert_contains "[persisted ]        - KiB  candidate path itself is declared"
assert_contains "[children  ]        - KiB  child paths are declared"
assert_contains "[candidate ]        - KiB  not declared"
assert_contains "[ignored   ]        - KiB  intentionally ignored for now"
assert_contains "### Inside default candidate scan"
assert_contains "### Outside default candidate scan"
assert_contains "${tmpdir}/etc/machine-id"
assert_contains "[persisted ]"
assert_contains "[children  ]"
assert_contains "${tmpdir}/etc/ssh"
assert_contains "[candidate ]"
assert_contains "${tmpdir}/var/lib/systemd"
assert_contains "## Top-level /var/cache candidates"
assert_contains "${tmpdir}/var/cache/steam"
assert_contains "## Top-level /var/tmp candidates"
assert_contains "${tmpdir}/var/tmp/steam"
assert_contains "[ignored   ]"
assert_contains "${tmpdir}/root"
assert_contains "${tmpdir}/etc/ssh/ssh_host_ed25519_key"

log_ok "$scope" "fixture coverage for persistence report passed"

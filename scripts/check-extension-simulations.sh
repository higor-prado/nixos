#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "extension-simulations" "$1"
  fail=1
}

# Verify that extendModules on aurelius keeps role=server and evaluates.
server_json="$(
  nix eval --json --impure --expr "
    let
      flake = builtins.getFlake \"path:${PWD}\";
      cfg = (flake.nixosConfigurations.aurelius.extendModules {
        modules = [
          ({ lib, ... }: {
            networking.hostName = lib.mkForce \"synthetic-ext-host\";
          })
          {
            custom.host.role = \"server\";
          }
        ];
      }).config;
    in
    {
      role = cfg.custom.host.role;
      systemDrv = cfg.system.build.toplevel.drvPath;
    }
  "
)"

if [[ "$(jq -r '.role' <<<"$server_json")" != "server" ]]; then
  report_fail "synthetic host simulation must keep role=server"
fi

if [[ "$(jq -r '.systemDrv' <<<"$server_json")" != /nix/store/* ]]; then
  report_fail "synthetic server host simulation produced invalid system drv path"
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "[extension-simulations] ok: synthetic host simulation checks passed"

#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"
repo_root="$(pwd)"
username="$(
  nix_eval_sole_hm_user_for_host predator
)"

report_fail() {
  log_fail "desktop-matrix" "$1"
}

require_cmds "desktop-matrix" "jq" "nix"

composition_module_name() {
  case "$1" in
    dms-on-niri) echo "desktop-dms-on-niri" ;;
    niri-standalone) echo "desktop-niri-standalone" ;;
    *) return 1 ;;
  esac
}

feature_module_expr() {
  case "$1" in
    dms-on-niri)
      cat <<'EOF2'
            nixos.niri
            nixos.dms
EOF2
      ;;
    niri-standalone)
      cat <<'EOF2'
            nixos.niri
EOF2
      ;;
    *)
      return 1
      ;;
  esac
}

greeter_expr() {
  case "$1" in
    dms-on-niri)
      cat <<'EOF2'
        cfg.programs.dank-material-shell.greeter.compositor.name
EOF2
      ;;
    niri-standalone)
      cat <<'EOF2'
        null
EOF2
      ;;
    *)
      return 1
      ;;
  esac
}

# Expected composition-level parameters per composition.
# Only composition parameterization is checked here (standalone, greeter).
# Feature program enablement is verified by the predator full build gate.
expected_feature_json() {
  case "$1" in
    dms-on-niri)
      cat <<'EOF2'
{"standalone":false,"greeter":"niri"}
EOF2
      ;;
    niri-standalone)
      cat <<'EOF2'
{"standalone":true,"greeter":null}
EOF2
      ;;
    *)
      report_fail "missing expected feature mapping for experience '$1'"
      return 1
      ;;
  esac
}

check_experience() {
  local experience="$1"
  local module_name feature_modules greeter_expr_text expected_json json system_drv expected actual key

  module_name="$(composition_module_name "$experience")" || {
    report_fail "missing module name for experience '$experience'"
    return 1
  }
  feature_modules="$(feature_module_expr "$experience")" || {
    report_fail "missing feature module mapping for experience '$experience'"
    return 1
  }
  greeter_expr_text="$(greeter_expr "$experience")" || {
    report_fail "missing greeter expression for experience '$experience'"
    return 1
  }
  expected_json="$(expected_feature_json "$experience")" || return 1

  json="$(
    nix_eval_json_expr "
      let
        flake = builtins.getFlake \"path:${repo_root}\";
        inherit (flake.modules) nixos;
        system = \"x86_64-linux\";
        username = \"${username}\";
        inputs = flake.inputs;
        lib = flake.inputs.nixpkgs.lib;
        composition = nixos.\"${module_name}\";
        systemConfig = lib.nixosSystem {
          inherit system;
          modules = [
            inputs.niri.nixosModules.niri
            inputs.dms.nixosModules.dank-material-shell
            inputs.dms.nixosModules.greeter
            inputs.home-manager.nixosModules.home-manager
            inputs.keyrs.nixosModules.default
${feature_modules}
            composition
            {
              nixpkgs.hostPlatform.system = system;
              networking.hostName = \"desktop-matrix\";
              users.users.\${username} = { isNormalUser = true; };
              home-manager.users.\${username}.home.stateVersion = \"25.11\";
              nixpkgs.config.allowUnfree = true;
              boot.isContainer = true;
              networking.useHostResolvConf = lib.mkForce false;
              fileSystems.\"/\" = {
                device = \"none\";
                fsType = \"tmpfs\";
              };
            }
          ];
        };
        cfg = systemConfig.config;
      in
      {
        standalone = cfg.custom.niri.standaloneSession;
        greeter = ${greeter_expr_text};
        systemDrv = cfg.system.build.toplevel.drvPath;
      }
    "
  )"

  for key in standalone greeter; do
    expected="$(jq -r ".${key}" <<<"$expected_json")"
    actual="$(jq -r ".${key}" <<<"$json")"
    if [[ "$actual" != "$expected" ]]; then
      report_fail "${experience} feature '${key}' expected '${expected}', got '${actual}'"
      return 1
    fi
  done

  system_drv="$(jq -r '.systemDrv' <<<"$json")"
  if [[ "$system_drv" != /nix/store/* ]]; then
    report_fail "invalid system drv path for ${experience}: ${system_drv}"
    return 1
  fi
  echo "[desktop-matrix] ok: $experience (systemDrv/features)"
}

for experience in \
  dms-on-niri \
  niri-standalone; do
  check_experience "$experience"
done

echo "[desktop-matrix] all concrete desktop experiences evaluated successfully"

#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/nix_eval.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "config-contracts" "$1"
  fail=1
}

expect_equal() {
  local label="$1"
  local got="$2"
  local expected="$3"
  if [ "$got" != "$expected" ]; then
    report_fail "${label}: expected '${expected}', got '${got}'"
  fi
}

require_cmds "config-contracts" "jq" "nix" "rg"

bool_eval() {
  nix eval --json "$1" | jq -r "."
}

bool_eval_expr() {
  nix_eval_json_expr "$1" | jq -r "."
}

host_cfg_expr() {
  local host="$1"
  local body="$2"
  bool_eval_expr "let cfg = (builtins.getFlake \"path:${PWD}\").nixosConfigurations.${host}.config; in ${body}"
}


predator_hm_user="$(nix_eval_sole_hm_user_for_host "predator")"

expect_equal "predator hyprland feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.programs.hyprland.enable")" "true"
expect_equal "predator regreet feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.programs.regreet.enable")" "true"
expect_equal "predator hyprlock feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.programs.hyprlock.enable")" "false"
expect_equal "predator fcitx5 feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.i18n.inputMethod.enable")" "true"
expect_equal "predator gnome-keyring feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.services.gnome.gnome-keyring.enable")" "true"
expect_equal "predator nautilus feature" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.services.gvfs.enable")" "true"
expect_equal "predator keyrs service" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.services.keyrs.enable")" "true"
expect_equal "predator waypaper feature" "$(host_cfg_expr "predator" "if builtins.hasAttr \"home-manager\" cfg && builtins.hasAttr \"users\" cfg.home-manager && builtins.hasAttr \"${predator_hm_user}\" cfg.home-manager.users && builtins.hasAttr \"home\" cfg.home-manager.users.${predator_hm_user} && builtins.hasAttr \"packages\" cfg.home-manager.users.${predator_hm_user}.home then builtins.any (pkg: (pkg.pname or null) == \"waypaper\") cfg.home-manager.users.${predator_hm_user}.home.packages else false")" "true"
expect_equal "predator uinput support" "$(bool_eval "path:$PWD#nixosConfigurations.predator.config.hardware.uinput.enable")" "true"

expect_equal "aurelius hyprland feature" "$(host_cfg_expr "aurelius" 'if builtins.hasAttr "hyprland" cfg.programs then cfg.programs.hyprland.enable else false')" "false"
expect_equal "aurelius regreet feature" "$(host_cfg_expr "aurelius" 'if builtins.hasAttr "regreet" cfg.programs then cfg.programs.regreet.enable else false')" "false"
expect_equal "aurelius hyprlock feature" "$(host_cfg_expr "aurelius" 'if builtins.hasAttr "hyprlock" cfg.programs then cfg.programs.hyprlock.enable else false')" "false"
expect_equal "aurelius fcitx5 feature" "$(bool_eval "path:$PWD#nixosConfigurations.aurelius.config.i18n.inputMethod.enable")" "false"
expect_equal "aurelius gnome-keyring feature" "$(bool_eval "path:$PWD#nixosConfigurations.aurelius.config.services.gnome.gnome-keyring.enable")" "false"
expect_equal "aurelius nautilus feature" "$(bool_eval "path:$PWD#nixosConfigurations.aurelius.config.services.gvfs.enable")" "false"
expect_equal "aurelius keyrs service" "$(host_cfg_expr "aurelius" 'if builtins.hasAttr "keyrs" cfg.services then cfg.services.keyrs.enable else false')" "false"
expect_equal "aurelius uinput support" "$(bool_eval "path:$PWD#nixosConfigurations.aurelius.config.hardware.uinput.enable")" "false"

mapfile -t declared_hosts < <(
  nix_eval_json_expr "builtins.attrNames (builtins.getFlake \"path:${PWD}\").nixosConfigurations" \
    | jq -r '.[]'
)

declare -A resolved_users=()
for host in "${declared_hosts[@]}"; do
  [[ -z "$host" ]] && continue
  host_user="$(nix_eval_sole_hm_user_for_host "$host")"
  case "$host_user" in
    ""|"root"|"user")
      report_fail "host '${host}' resolved unsafe username='${host_user}'"
      ;;
    *)
      resolved_users["$host_user"]=1
      ;;
  esac
done

for hm_user in "${!resolved_users[@]}"; do
  if rg -n "home-manager\.users\.${hm_user}\." .github scripts docs/for-humans README.md docs/for-agents/[0-9][0-9][0-9]-*.md >/dev/null; then
    report_fail "found hardcoded home-manager user '${hm_user}' in tracked CI/script/docs paths"
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[config-contracts] ok: role/feature/selected-user invariants hold"

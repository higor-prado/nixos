#!/usr/bin/env bash

nix_eval_json_expr() {
  local expr="$1"
  nix eval --json --impure --expr "$expr"
}

nix_eval_raw_expr() {
  local expr="$1"
  nix eval --raw --impure --expr "$expr"
}

nix_eval_sole_hm_user_for_host() {
  local host="$1"
  nix_eval_raw_expr "
    let
      cfg = (builtins.getFlake \"path:${PWD}\").nixosConfigurations.${host}.config;
      users =
        if builtins.hasAttr \"home-manager\" cfg && builtins.hasAttr \"users\" cfg.home-manager
        then builtins.attrNames cfg.home-manager.users
        else [ ];
    in
      if builtins.length users == 1
      then builtins.head users
      else throw \"expected exactly one home-manager user for ${host}\"
  "
}

#!/usr/bin/env bash

# shellcheck source=nix_eval.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/nix_eval.sh"

extc_host_descriptor_names() {
  nix_eval_json_expr "builtins.attrNames (import ${PWD}/hardware/host-descriptors.nix)" \
    | jq -r '.[]' \
    | sort -u
}

extc_host_runtime_role() {
  local host="$1"
  nix eval --raw "path:${PWD}#nixosConfigurations.${host}.config.custom.host.role"
}

extc_host_descriptor_has_legacy_desktop_selector() {
  local host="$1"
  [[ "$(
    nix_eval_raw_expr "
    let
      descriptor = (import ${PWD}/hardware/host-descriptors.nix).\"${host}\";
    in
      if builtins.hasAttr (\"desktop\" + \"Profile\") descriptor then \"true\" else \"false\"
  "
  )" == "true" ]]
}

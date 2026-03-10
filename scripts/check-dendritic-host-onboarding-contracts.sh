#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

scope="dendritic-host-onboarding"
require_cmds "$scope" "nix" "jq"

descriptors_file="${DENDRITIC_HOST_DESCRIPTORS_FILE:-hardware/host-descriptors.nix}"
if [[ "$descriptors_file" != /* ]]; then
  descriptors_file="$PWD/$descriptors_file"
fi

if [[ ! -f "$descriptors_file" ]]; then
  log_fail "$scope" "missing host descriptors file: $descriptors_file"
  exit 1
fi

eval_expr="let hosts = import ${descriptors_file}; in builtins.mapAttrs (name: v: {
  hasIntegrations = builtins.hasAttr \"integrations\" v;
  integrationsIsAttrset = (builtins.hasAttr \"integrations\" v) && (builtins.typeOf v.integrations == \"set\");
  integrationsAllBool =
    (builtins.hasAttr \"integrations\" v)
    && (builtins.typeOf v.integrations == \"set\")
    && (builtins.all (k: builtins.typeOf v.integrations.\${k} == \"bool\") (builtins.attrNames v.integrations));
  hasRole = builtins.hasAttr \"role\" v;
  hasSystem = builtins.hasAttr \"system\" v;
  hasDendriticField = builtins.hasAttr \"dendritic\" v;
  hasLegacyModulesField = (builtins.hasAttr \"modules\" v) || (builtins.hasAttr \"imports\" v);
  hasLegacyDesktopSelector = builtins.hasAttr (\"desktop\" + \"Profile\") v;
}) hosts"

if ! eval_json="$(nix eval --impure --json --expr "$eval_expr")"; then
  log_fail "$scope" "failed to evaluate host descriptors from: $descriptors_file"
  exit 1
fi

host_count="$(jq -r 'length' <<<"$eval_json")"
if [[ "$host_count" == "0" ]]; then
  log_fail "$scope" "host descriptors must define at least one host"
  exit 1
fi

fail=0
report_missing_hosts() {
  local label="$1"
  local filter="$2"
  local hosts
  hosts="$(jq -r "$filter" <<<"$eval_json" | tr '\n' ',' | sed 's/,$//')"
  if [[ -n "$hosts" ]]; then
    log_fail "$scope" "$label: $hosts"
    fail=1
  fi
}

report_missing_hosts "hosts missing integrations attrset" 'to_entries[] | select(.value.hasIntegrations | not) | .key'
report_missing_hosts "hosts with integrations not declared as an attrset" 'to_entries[] | select(.value.integrationsIsAttrset | not) | .key'
report_missing_hosts "hosts with non-bool integration values" 'to_entries[] | select(.value.integrationsAllBool | not) | .key'
report_missing_hosts "hosts declaring duplicated role field" 'to_entries[] | select(.value.hasRole) | .key'
report_missing_hosts "hosts declaring duplicated system field" 'to_entries[] | select(.value.hasSystem) | .key'
report_missing_hosts "hosts declaring deprecated dendritic pilot field" 'to_entries[] | select(.value.hasDendriticField) | .key'
report_missing_hosts "hosts declaring legacy desktop selector field" 'to_entries[] | select(.value.hasLegacyDesktopSelector) | .key'
report_missing_hosts "hosts declaring legacy modules/imports fields" 'to_entries[] | select(.value.hasLegacyModulesField) | .key'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

log_ok "$scope" "host descriptors satisfy composition-first onboarding contracts"

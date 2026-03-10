#!/usr/bin/env bash

runtime_warning_budget_count_pattern() {
  local pattern="$1"
  local log_file="$2"
  (rg -F "$pattern" "$log_file" || true) | wc -l | tr -d ' '
}

runtime_warning_budget_scan() {
  local scope="$1"
  local budget_file="$2"
  local log_file="$3"
  local strict_logs="$4"
  local -n out_warning_overruns_ref="$5"
  local -n out_budget_expired_ref="$6"

  if [[ ! -f "$budget_file" ]]; then
    log_fail "$scope" "missing warning budget file: ${budget_file}"
    return 1
  fi

  if ! jq -e '.version == 1 and (.failPatterns | type == "array") and (.warningThresholds | type == "array")' "$budget_file" >/dev/null; then
    log_fail "$scope" "invalid warning budget schema in ${budget_file}"
    return 1
  fi

  out_warning_overruns_ref=0
  out_budget_expired_ref=0

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local id pattern owner count
    id="$(jq -r '.id' <<<"$entry")"
    pattern="$(jq -r '.pattern' <<<"$entry")"
    owner="$(jq -r '.owner // "unowned"' <<<"$entry")"
    count="$(runtime_warning_budget_count_pattern "$pattern" "$log_file")"

    if [ "$count" -gt 0 ]; then
      log_fail "$scope" "${id}: found ${count} occurrences of '${pattern}'"
      return 1
    fi
    log_ok "$scope" "${id}: no occurrences for '${pattern}'"
    log_ok "$scope" "${id}: owner=${owner}"
  done < <(jq -c '.failPatterns[]' "$budget_file")

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local id pattern default_max env_override owner expires_on max override_value count today_utc

    id="$(jq -r '.id' <<<"$entry")"
    pattern="$(jq -r '.pattern' <<<"$entry")"
    default_max="$(jq -r '.defaultMax' <<<"$entry")"
    env_override="$(jq -r '.envOverride // ""' <<<"$entry")"
    owner="$(jq -r '.owner // "unowned"' <<<"$entry")"
    expires_on="$(jq -r '.expiresOn // ""' <<<"$entry")"

    max="$default_max"
    if [[ -n "$env_override" ]]; then
      override_value="${!env_override:-}"
      if [[ -n "$override_value" ]]; then
        max="$override_value"
      fi
    fi

    count="$(runtime_warning_budget_count_pattern "$pattern" "$log_file")"

    if [[ -n "$expires_on" ]]; then
      today_utc="$(date -u +%F)"
      if [[ "$expires_on" < "$today_utc" ]]; then
        if [ "$strict_logs" -eq 1 ]; then
          log_fail "$scope" "${id}: accepted warning budget expired on ${expires_on} (owner: ${owner})"
          return 1
        fi
        log_warn "$scope" "${id}: accepted warning budget expired on ${expires_on} (owner: ${owner})"
        out_budget_expired_ref=$((out_budget_expired_ref + 1))
      fi
    fi

    if [ "$count" -gt "$max" ]; then
      if [ "$strict_logs" -eq 1 ]; then
        log_fail "$scope" "${id}: count ${count} exceeds max ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
        return 1
      fi
      log_warn "$scope" "${id}: count ${count} exceeds max ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
      out_warning_overruns_ref=$((out_warning_overruns_ref + 1))
      continue
    fi

    log_ok "$scope" "${id}: count ${count} <= ${max} for '${pattern}' (owner: ${owner}, expiresOn: ${expires_on})"
  done < <(jq -c '.warningThresholds[]' "$budget_file")
}

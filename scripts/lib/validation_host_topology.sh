#!/usr/bin/env bash

# Shared validation host topology for local gates, KPI reporting, and CI policy.
# Keep the declared stage list here so host validation stages are not repeated
# across multiple shell entrypoints.

validation_host_stages() {
  printf '%s\n' \
    "predator" \
    "aurelius"
}

ci_validation_host_stages() {
  printf '%s\n' \
    "predator" \
    "aurelius"
}

validation_stage_host() {
  case "${1:-}" in
    predator) printf '%s\n' "predator" ;;
    aurelius) printf '%s\n' "aurelius" ;;
    *) return 1 ;;
  esac
}

validation_stage_mode() {
  case "${1:-}" in
    predator) printf '%s\n' "build" ;;
    aurelius) printf '%s\n' "eval" ;;
    *) return 1 ;;
  esac
}

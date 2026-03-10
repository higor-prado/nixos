#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

scope="dendritic-host-onboarding-contracts-fixture-test"

valid_file="tests/fixtures/dendritic-host-onboarding/valid/host-descriptors.nix"
invalid_file="tests/fixtures/dendritic-host-onboarding/invalid/host-descriptors.nix"
template_file="tests/fixtures/dendritic-host-onboarding/template/new-host-descriptors.nix"

DENDRITIC_HOST_DESCRIPTORS_FILE="$valid_file" ./scripts/check-dendritic-host-onboarding-contracts.sh >/dev/null
DENDRITIC_HOST_DESCRIPTORS_FILE="$template_file" ./scripts/check-dendritic-host-onboarding-contracts.sh >/dev/null

if DENDRITIC_HOST_DESCRIPTORS_FILE="$invalid_file" ./scripts/check-dendritic-host-onboarding-contracts.sh >/dev/null 2>&1; then
  log_fail "$scope" "expected failure for invalid host onboarding fixture"
  exit 1
fi

log_ok "$scope" "dendritic host onboarding fixture checks passed"

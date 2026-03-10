#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmd "docs-drift" "rg"

targets=(
  README.md
  AGENTS.md
  docs/for-agents/000-operating-rules.md
  docs/for-agents/001-repo-map.md
  docs/for-agents/002-den-architecture.md
  docs/for-agents/003-module-ownership.md
  docs/for-agents/004-private-safety.md
  docs/for-agents/005-validation-gates.md
  docs/for-agents/006-extensibility.md
  docs/for-agents/007-option-migrations.md
  docs/for-agents/999-lessons-learned.md
  docs/for-humans/00-start-here.md
  docs/for-humans/01-philosophy.md
  docs/for-humans/02-structure.md
  docs/for-humans/03-multi-host.md
  docs/for-humans/04-private-overrides.md
  docs/for-humans/05-dev-environment.md
  docs/for-humans/workflows/101-switch-and-rollback.md
  docs/for-humans/workflows/102-add-feature.md
  docs/for-humans/workflows/103-add-host.md
  docs/for-humans/workflows/104-add-desktop-experience.md
  docs/for-humans/workflows/105-private-overrides.md
  docs/for-humans/workflows/106-deploy-aurelius.md
)

resolve_reference() {
  local source_file="$1"
  local ref="$2"

  # Direct hit from repo root.
  if [ -e "$ref" ]; then
    return 0
  fi

  # Normalize leading ./ references.
  if [[ "$ref" == ./* ]] && [ -e "${ref#./}" ]; then
    return 0
  fi

  # Resolve relative to source doc directory.
  local source_dir
  source_dir="$(dirname "$source_file")"
  if [ -e "$source_dir/$ref" ]; then
    return 0
  fi

  # Nix module shorthand: look in common module directories.
  if [[ "$ref" == *.nix ]]; then
    for module_dir in modules/features modules/desktops modules/hosts modules/lib home/base; do
      if [ -e "$module_dir/$ref" ]; then
        return 0
      fi
    done
    # Also try hardware/predator subdirs for hardware splits
    for hw_dir in hardware/predator/hardware hardware/predator hardware/aurelius; do
      if [ -e "$hw_dir/$ref" ]; then
        return 0
      fi
    done
  fi

  # Script shorthand: look in scripts/ for .sh files.
  if [[ "$ref" == *.sh && "$ref" != */* ]]; then
    if [ -e "scripts/$ref" ]; then
      return 0
    fi
  fi

  # Common docs shorthand: same collection filename only.
  if [[ "$ref" == *.md && "$ref" != */* ]]; then
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-humans* && -e "docs/for-humans/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-humans* && -e "docs/for-humans/workflows/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/reference/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/plans/$ref" ]]; then
      return 0
    fi
    if [[ "$source_dir" == docs/for-agents* && -e "docs/for-agents/current-work/$ref" ]]; then
      return 0
    fi
  fi

  return 1
}

fail=0
checked=0

for source in "${targets[@]}"; do
  [ -f "$source" ] || continue

  # shellcheck disable=SC2016
  mapfile -t refs < <(
    {
      rg -No '`([A-Za-z0-9._/-]+\.(sh|nix|md|yml))`' "$source" | sed -E 's/.*`([^`]+)`.*/\1/'
      rg -No '\((docs/[A-Za-z0-9._/-]+\.md)\)' "$source" | sed -E 's/.*\((docs\/[A-Za-z0-9._\/-]+\.md)\).*/\1/'
    } | sed '/^$/d' | sort -u
  )

  for ref in "${refs[@]}"; do
    case "$ref" in
      http://*|https://*) continue ;;
    esac
    checked=$((checked + 1))
    if ! resolve_reference "$source" "$ref"; then
      log_fail "docs-drift" "missing referenced path from $source: $ref"
      fail=1
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[docs-drift] ok: ${checked} references validated in living docs"

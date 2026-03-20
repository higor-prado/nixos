#!/usr/bin/env bash
# check-flake-inputs-used.sh — gate against unused flake inputs (lesson 20).
# Dead inputs accumulate silently; this gate flags any declared input with zero
# references outside the flake.lock file.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

# Inputs wired implicitly by the framework — no explicit reference in our code needed.
always_used=("nixpkgs" "flake-parts" "import-tree")

# Extract declared top-level input names from flake.nix.
# Top-level inputs are indented with exactly 4 spaces and followed by . { or =.
mapfile -t declared_inputs < <(grep -oP '^    \K[a-zA-Z0-9_-]+(?=\s*[.={])' flake.nix)

fail=0

for name in "${declared_inputs[@]}"; do
  # Skip always-used framework inputs.
  skip=0
  for au in "${always_used[@]}"; do
    [[ "$name" == "$au" ]] && skip=1 && break
  done
  [[ $skip -eq 1 ]] && continue

  # Search 1: inputs.<name> or inputs."<name>" (quoted form used for hyphenated names).
  #            Searches all .nix files including flake.nix outputs section; excludes flake.lock.
  refs=$(
    grep -rl \
      -e "inputs\\.${name}" \
      -e "inputs\\.\"${name}\"" \
      --include='*.nix' . --exclude='flake.lock' 2>/dev/null || true
  )

  # Search 2: <name>. usage at module level (e.g. home-manager.nixosModules)
  #            in .nix files excluding flake.nix (to avoid matching the declaration itself)
  #            and flake.lock.
  if [[ -z "$refs" ]]; then
    refs=$(
      grep -rl "\\b${name}\\." --include='*.nix' . \
        --exclude='flake.nix' --exclude='flake.lock' 2>/dev/null || true
    )
  fi

  if [[ -z "$refs" ]]; then
    echo "[check-flake-inputs-used] FAIL: input '${name}' is declared but not referenced anywhere" >&2
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "[check-flake-inputs-used] unused flake inputs found — remove them from flake.nix" >&2
  exit 1
fi

echo "[check-flake-inputs-used] ok"

# Fix `check-flake-pattern.sh` short-form input blind spot

## Goal

Eliminate the blind spot in `check-flake-pattern.sh` where flake inputs declared
in the short form `key.url = "..."` are excluded from kebab-case validation,
allowing invalid names like `nixpkgs-tailscale-1_96_5` to pass silently.

## Scope

In scope:

- Fix the AWK input-name extraction to capture **all** declaration forms
- Add fixture-based regression test for the kebab-case check
- Verify the fix catches the existing `nixpkgs-tailscale-1_96_5` violation
- Run validation gates to confirm no regressions

Out of scope:

- Fixing the `nixpkgs-tailscale-1_96_5` name itself (separate commit, separate concern)
- Changing any other gate scripts
- Changing the `-src` suffix check (not affected — no short-form input uses `flake = false`)

## Current State

- **File:** `scripts/check-flake-pattern.sh`
- **Bug location:** Lines 28–42 (first AWK block)
- **Root cause:** The AWK regex `match($0, /^[[:space:]]*([A-Za-z0-9._-]+)[[:space:]]*=/, m)`
  captures the full dotted form for short-form inputs (e.g. `nixpkgs.url`,
  `nixpkgs-tailscale-1_96_5.url`). The filter `index(key, ".") == 0` then
  discards them, because they contain a dot. Only block-form inputs
  (`key = { ... }`) survive to the kebab-case check.
- **Affected inputs in the real `flake.nix`:**
  - `nixpkgs` — valid kebab-case, but was never checked
  - `import-tree` — valid kebab-case, but was never checked
  - `nixpkgs-tailscale-1_96_5` — **violates** kebab-case (contains `_`), was never checked
- **No existing fixture test** for the kebab-case validation logic — the
  `run-validation-gates-fixture-test.sh` only verifies that the script is
  _invoked_ by the runner, not its actual correctness.
- **Total root inputs:** 20 (3 short-form + 17 block-form). The gate currently
  validates only the 17 block-form inputs.

### Nix input declaration forms

Form A (short/dot): `    key.url = "...";`
Form B (block): `    key = { url = "..."; ... };`

Both are semantically identical in Nix. The gate must validate both.

## Desired End State

- `check-flake-pattern.sh` validates **all** 20 root inputs for kebab-case
- The existing `nixpkgs-tailscale-1_96_5` is correctly flagged as a violation
- A fixture test proves the fix works for both declaration forms
- No regression in any other gate check

## Phases

### Phase 0: Baseline

Validation:

```bash
# Confirm the blind spot exists
bash scripts/check-flake-pattern.sh
# Expected: exits 0 (misses the underscore violation)

# List which inputs the current AWK captures
awk '
  /inputs = \{/ { in_inputs = 1; depth = 1; next }
  in_inputs {
    opens = gsub(/\{/, "{")
    closes = gsub(/\}/, "}")
    if (depth == 1 && match($0, /^[[:space:]]*([A-Za-z0-9._-]+)[[:space:]]*=/, m)) {
      key = m[1]
      if (index(key, ".") == 0) print key
    }
    depth += opens - closes
    if (depth == 0) exit
  }
' flake.nix | sort -u | wc -l
# Expected: 17 (missing 3 short-form inputs)
```

### Phase 1: Fix the AWK extraction logic

Targets:

- `scripts/check-flake-pattern.sh` lines 28–42 (first AWK block)

Changes:
Replace the first AWK block with a version that handles both forms:

```awk
/inputs = \{/ { in_inputs = 1; depth = 1; next }
in_inputs {
    opens = gsub(/\{/, "{")
    closes = gsub(/\}/, "}")
    if (depth == 1) {
        # Form A: key.url = "..."  →  extract key before the dot
        if (match($0, /^[[:space:]]*([A-Za-z0-9_-]+)\.url[[:space:]]*=/, m)) {
            print m[1]
        }
        # Form B: key = { ... }  →  extract key before the brace
        else if (match($0, /^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*[{]/, m)) {
            print m[1]
        }
    }
    depth += opens - closes
    if (depth == 0) exit
}
```

Key design decisions:

1. **Two separate `match()` calls instead of one unified regex.** The dot-form
   (`key.url =`) and block-form (`key = {`) have distinct patterns. Trying to
   unify them into one regex makes the capture group ambiguous and fragile.
2. **Explicit `else if`.** A line cannot be both forms simultaneously, so no
   double-counting is possible.
3. **No `index(key, ".") == 0` filter.** Each `match()` now captures only the
   input name (before the dot or brace), so the filter is no longer needed.
4. **Character class `[A-Za-z0-9_-]+`.** Matches the same set as before, minus
   the dot — since we no longer need to match through `.url`.

Validation:

```bash
# Should now exit 1 with a failure for nixpkgs-tailscale-1_96_5
bash scripts/check-flake-pattern.sh 2>&1
# Expected output includes:
# [FAIL] flake-pattern: input 'nixpkgs-tailscale-1_96_5' is not kebab-case

# Confirm all 20 inputs are now captured
awk '
  /inputs = \{/ { in_inputs = 1; depth = 1; next }
  in_inputs {
    opens = gsub(/\{/, "{")
    closes = gsub(/\}/, "}")
    if (depth == 1) {
      if (match($0, /^[[:space:]]*([A-Za-z0-9_-]+)\.url[[:space:]]*=/, m)) print m[1]
      else if (match($0, /^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*[{]/, m)) print m[1]
    }
    depth += opens - closes
    if (depth == 0) exit
  }
' flake.nix | sort -u | wc -l
# Expected: 20
```

Diff expectation:

- Only `scripts/check-flake-pattern.sh` changes
- ~10 lines modified (AWK block replacement)

Commit target:

- `fix(validation): capture short-form flake inputs in kebab-case check`

### Phase 2: Add fixture-based regression test

Targets:

- New file: `tests/scripts/check-flake-pattern-fixture-test.sh`

The existing fixture tests (`run-validation-gates-fixture-test.sh`,
`audit-nix-ld-usage-fixture-test.sh`) follow a pattern:

1. Create a temp directory with fixture files
2. Run the script under test against the fixture
3. Assert on exit code and output

The test should cover:

| Case | `flake.nix` fixture                                             | Expected |
| ---- | --------------------------------------------------------------- | -------- |
| A1   | Block-form input with valid kebab-case (`my-input = { ... }`)   | PASS     |
| A2   | Block-form input with invalid name (`my_input = { ... }`)       | FAIL     |
| B1   | Short-form input with valid kebab-case (`my-input.url = "..."`) | PASS     |
| B2   | Short-form input with invalid name (`my_input.url = "..."`)     | FAIL     |
| C1   | Mix of both forms, all valid                                    | PASS     |
| C2   | Mix of both forms, one invalid short-form                       | FAIL     |

Test structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

scope="check-flake-pattern-fixture-test"

# Helper: create a minimal flake.nix with given inputs, run the check,
# and assert exit code.
run_check() {
  local flake_content="$1"
  local expected_exit="$2"
  local tmpdir
  tmpdir="$(mktemp_dir_scoped "$scope")"
  trap 'rm -rf "$tmpdir"' RETURN

  printf '%s\n' "$flake_content" >"$tmpdir/flake.nix"
  # Create minimal repo structure the script expects
  mkdir -p "$tmpdir/scripts/lib"
  cp scripts/lib/common.sh "$tmpdir/scripts/lib/"
  # The script reads flake.nix from CWD
  local actual_exit=0
  cd "$tmpdir"
  bash "$REPO_ROOT/scripts/check-flake-pattern.sh" 2>/dev/null || actual_exit=$?
  cd "$REPO_ROOT"

  if [ "$actual_exit" -ne "$expected_exit" ]; then
    log_fail "$scope" "expected exit $expected_exit, got $actual_exit"
    return 1
  fi
}

# ... test cases ...
```

Validation:

```bash
bash tests/scripts/check-flake-pattern-fixture-test.sh
# All test cases pass
```

Commit target:

- `test(validation): add fixture test for flake input kebab-case check`

### Phase 3: Wire the fixture test into the gate runner

Targets:

- `scripts/run-validation-gates.sh` — add the new test to the structure stage
- `tests/pyramid/shared-script-registry.tsv` — register the test
- `tests/scripts/run-validation-gates-fixture-test.sh` — add to the stub list
- `docs/for-agents/005-validation-gates.md` — document the new test

Changes:

1. In `run-validation-gates.sh`, add `check-flake-pattern-fixture-test.sh` to
   the structure-stage test list (same location as the other fixture tests).
2. In `shared-script-registry.tsv`, add an entry for the new test with category
   `test-fixture`.
3. In `run-validation-gates-fixture-test.sh`, add the new script name to the
   `test_scripts` array so the runner-orchestration contract stays valid.
4. In `005-validation-gates.md`, add `check-flake-pattern-fixture-test.sh` to
   the list of fixture tests in the structure stage section.

Validation:

```bash
# Full gate runner passes
bash scripts/run-validation-gates.sh structure
# The new test is listed and runs

# Gate runner fixture test still passes
bash tests/scripts/run-validation-gates-fixture-test.sh
```

Commit target:

- `chore(validation): wire flake-pattern fixture test into gate runner`

### Phase 4: End-to-end verification

After all phases are committed:

```bash
# Full validation
bash scripts/run-validation-gates.sh

# Confirm the real flake.nix violation is detected
bash scripts/check-flake-pattern.sh 2>&1
# Must show: [FAIL] flake-pattern: input 'nixpkgs-tailscale-1_96_5' is not kebab-case
```

Note: the gate runner will **fail** at this point because
`nixpkgs-tailscale-1_96_5` is a real violation. That is expected — the plan
only fixes the blind spot. Renaming the input is a separate follow-up task
that requires updating `flake.nix`, `flake.lock`, and all references.

## Risks

| Risk                                                                                 | Mitigation                                                                                                  |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| AWK regex change could miss edge cases in Nix syntax (e.g., `key.\nurl`)             | Nix allows multi-line attrs but the repo consistently uses single-line form; test fixtures cover both forms |
| Fixture test needs `common.sh` sourced — path assumptions                            | Follow the same pattern as existing fixture tests (`audit-nix-ld-usage-fixture-test.sh`)                    |
| Fixing the blind spot makes the gate fail on the existing `nixpkgs-tailscale-1_96_5` | That is the correct behavior. The input name fix is a separate concern outside this plan                    |

## Definition of Done

- [ ] `check-flake-pattern.sh` captures all 20 root inputs (3 short-form + 17 block-form)
- [ ] The script correctly flags `nixpkgs-tailscale-1_96_5` as non-kebab-case
- [ ] Fixture test covers both declaration forms with pass/fail cases
- [ ] Fixture test is wired into the structure stage of `run-validation-gates.sh`
- [ ] All existing gate checks pass (except the expected `nixpkgs-tailscale-1_96_5` violation)
- [ ] `docs/for-agents/005-validation-gates.md` updated
- [ ] `tests/pyramid/shared-script-registry.tsv` updated
- [ ] `tests/scripts/run-validation-gates-fixture-test.sh` updated

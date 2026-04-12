# Pre-commit Safety Hook Plan

## Goal

Run `check-repo-public-safety.sh` automatically on every commit to prevent
private data from ever reaching the local git history, not just the remote.

## Current State

- `check-repo-public-safety.sh` exists and runs in ~150ms
- CI runs it on push via `.github/workflows/validate.yml`
- No local pre-commit hooks exist
- No `.pre-commit-config.yaml` exists
- `pre-commit` 4.5.1 is available in nixpkgs

## Why CI is not enough

CI catches private data on push. But by then the commit already exists in the
local history. Cleaning that up requires `git rebase` or `git filter-branch`,
which is error-prone and destructive. A pre-commit hook catches it before the
commit is created — the fix is just editing the file and committing again.

## Desired End State

- One tracked `.pre-commit-config.yaml` with a single local hook
- The hook runs `check-repo-public-safety.sh` on every commit
- One-time setup documented: `nix run nixpkgs#pre-commit -- install`
- No new flake inputs

## Phases

### Phase 1: Add pre-commit config

Targets:
- `.pre-commit-config.yaml` (new file)

Changes:
- Create a minimal config with one local repo hook:
  ```yaml
  repos:
    - repo: local
      hooks:
        - id: check-repo-public-safety
          name: public safety
          entry: ./scripts/check-repo-public-safety.sh
          language: system
          pass_filenames: false
          always_run: true
  ```

  Design choices:
  - `language: system` — runs the script directly, no virtualenv overhead
  - `pass_filenames: false` — the script scans the whole repo, not individual files
  - `always_run: true` — runs on every commit, not just when matching files change
    (private data could appear in any file)

Validation:
- `nix run nixpkgs#pre-commit -- run --all-files` — verify the hook works
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- new file only; no closure changes

Commit target:
- `chore: add pre-commit config for public safety check`

### Phase 2: Document one-time setup

Targets:
- `docs/for-humans/05-dev-environment.md`

Changes:
- Add a note that running `nix run nixpkgs#pre-commit -- install` once after
  cloning sets up the pre-commit hooks. This is a one-time operation.

Validation:
- `./scripts/check-docs-drift.sh`

Commit target:
- `docs: document pre-commit setup step`

## Risks

| Risk | Mitigation |
|------|------------|
| User forgets to run `pre-commit install` after clone | Documented; CI still catches it on push as fallback |
| Hook slows down commits | Script runs in ~150ms; negligible |
| Hook blocks a commit the user wants to make | `git commit --no-verify` bypasses the hook; CI still checks |

## Definition of Done

- [ ] `.pre-commit-config.yaml` exists and the hook passes on the current repo
- [ ] One-time setup documented in dev-environment docs
- [ ] All validation gates pass

# Repo Audit Remediation — Doc Drift and Gaps

## Goal

Fix the medium-severity doc drift (mpd/rmpc copy-once vs declarative) and close
the low-severity documentation gaps (`opencode.json`, `templates/`, Fish
abbreviation pattern, and attic-client on aurelius) so that the repository
documentation matches actual code and all living docs are accurate.

## Scope

In scope:

- Fix documentation for mpd/rmpc provisioning method in `001-repo-map.md` and
  `AGENTS.md`
- Decide and act on `opencode.json` (gitignore vs document)
- Document `templates/` in `001-repo-map.md`
- Add `homeManager.attic-client` to aurelius host composition
- Normalize Fish abbreviation style across hosts (inline all, remove
  `mkPredatorConfig` dead indirection)
- Run full validation gates after each phase

Out of scope:

- Converting mpd/rmpc to copy-once (behavioral change — separate decision)
- Backup service on aurelius/cerebelo (intentional exclusion for servers)
- AIOStreams DNS parameterization (cosmetic, non-blocking)
- Changes to actual feature module behavior or packages

## Current State

- `config/apps/mpd/` and `config/apps/rmpc/` are documented as "provisioned by
  copy-once" but use `xdg.configFile.*.source` (declarative) in
  `modules/features/desktop/music-client.nix`
- `opencode.json` is tracked in git but not mentioned in any doc
- `templates/` directory (4 `.tpl` files for `new-host-skeleton.sh`) not in
  repo-map
- predator uses `mkPredatorConfig` abstraction with 1 caller; aurelius/cerebelo
  use inline Fish abbreviations
- aurelius does not import `homeManager.attic-client`
- All structure validation gates pass

## Desired End State

- All living docs accurately describe the actual provisioning method for every
  config payload
- `opencode.json` is either gitignored or documented
- `templates/` appears in `001-repo-map.md`
- All three hosts use the same Fish abbreviation pattern (inline)
- predator host module has no dead `mkPredatorConfig` indirection
- aurelius imports `homeManager.attic-client`
- All validation gates pass
- No behavioral changes to any host configuration

## Phases

### Phase 0: Baseline

Validation:

```
./scripts/run-validation-gates.sh structure
```

Confirm all gates pass before starting.

### Phase 1: Fix mpd/rmpc doc drift

Targets:

- `docs/for-agents/001-repo-map.md`
- `AGENTS.md` (mutable copy-once list)

Changes:

- In `001-repo-map.md`, change the mpd/rmpc entries from "provisioned by
  copy-once" to "provisioned declaratively via `xdg.configFile`".
- In `AGENTS.md`, remove `mpd` and `rmpc` from the "Mutable copy-once configs"
  list, or add a clarifying note that mpd/rmpc are declarative.

Validation:

- `./scripts/run-validation-gates.sh structure` (docs-drift gate)
- Manual read of changed lines to confirm accuracy

Diff expectation:

- Only documentation text changes; no Nix code changes.

Commit target:

- `fix(docs): correct mpd/rmpc provisioning method from copy-once to declarative`

### Phase 2: Resolve `opencode.json` tracking status

Targets:

- `opencode.json`
- `.gitignore`

Changes:

- Add `opencode.json` to `.gitignore`. It is a local developer tool config
  (MCP server connection for opencode) — not a repo-level concern, and it
  may contain paths or settings specific to the local machine.
- Remove `opencode.json` from git tracking: `git rm --cached opencode.json`

Validation:

- `./scripts/run-validation-gates.sh structure`
- `git status` shows opencode.json as deleted from tracking

Diff expectation:

- `opencode.json` no longer tracked
- `.gitignore` gains one line

Commit target:

- `chore: gitignore opencode.json as local developer tool config`

### Phase 3: Document `templates/` in repo-map

Targets:

- `docs/for-agents/001-repo-map.md`

Changes:

- Add a `templates/` entry to the top-level layout section:
  ```
  templates/         host skeleton templates for new-host-skeleton.sh
  ```
- Add a subsection under the extensibility area describing the 4 template files
  and their relationship to `scripts/new-host-skeleton.sh`.

Validation:

- `./scripts/run-validation-gates.sh structure` (docs-drift gate)

Diff expectation:

- Documentation only.

Commit target:

- `fix(docs): add templates/ directory to repo-map`

### Phase 4: Normalize Fish abbreviation style and remove dead indirection

Targets:

- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix` (already inline — verify)
- `modules/hosts/cerebelo.nix` (already inline — verify)

Changes:

- In `predator.nix`:
  - Inline the `operatorFishAbbrs` attrset directly into
    `programs.fish.shellAbbrs = { ... };`, matching the aurelius/cerebelo
    pattern.
  - Remove the `mkPredatorConfig` function wrapper. Replace the single call
    `predator.module = mkPredatorConfig nixosDesktop hmDesktop;` with the
    direct module expression using the already-defined `nixosDesktop` and
    `hmDesktop` lists (same structure as aurelius/cerebelo).
  - Keep the `let` bindings for the list groupings (`nixosInfrastructure`,
    `nixosCoreServices`, etc.) — those are readability helpers, not dead
    indirection.
- Verify aurelius and cerebelo are already inline (no changes expected).

Validation:

- `./scripts/run-validation-gates.sh structure`
- Diff the predator host eval before and after:
  ```bash
  nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
  ```
  The drvPath must be identical (no behavioral change).
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  Still evaluates correctly.

Diff expectation:

- `modules/hosts/predator.nix` changes structure but produces identical Nix
  eval output. The Fish abbreviations, imports, and all config values remain
  the same.

Commit target:

- `refactor(predator): inline fish abbreviations and remove mkPredatorConfig indirection`

### Phase 5: Add `attic-client` HM module to aurelius

Targets:

- `modules/hosts/aurelius.nix`

Changes:

- Add `homeManager.attic-client` to the `hmUserTools` list in the aurelius
  host composition.

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
  Evaluates successfully (may differ from baseline due to new package).
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.stateVersion`
  Still evaluates correctly.

Diff expectation:

- aurelius HM gains `attic-client` package in the user profile.
- Nix eval drvPath will change (new package).

Commit target:

- `feat(aurelius): add attic-client HM package for interactive use`

### Phase 6: Final validation

Run the full gate suite:

```bash
./scripts/run-validation-gates.sh
```

Then run per-host evals:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.stateVersion
```

Verify:

- All structure gates pass
- All host evals succeed
- Predator eval output is unchanged from Phase 0 baseline (phases 1-4 are
  doc/refactor only)
- Aurelius eval succeeds with the new attic-client package

## Risks

1. **Predator refactor (Phase 4)** — highest risk phase because it restructures
   the host module. Mitigated by verifying `drvPath` identity before/after.
   If drvPath differs, revert and inspect.
2. **opencode.json gitignore (Phase 2)** — the file remains on disk locally but
   is no longer tracked. If the user depends on it being in the repo (e.g. for
   other machines), this should be reverted.
3. **Docs-drift gate** — the gate validates 183 references. All changes must
   keep paths that exist and remove paths that don't. The changes in phases 1
   and 3 only modify description text, not path references.

## Definition of Done

- [ ] `001-repo-map.md` accurately describes mpd/rmpc as declarative
- [ ] `AGENTS.md` mutable copy-once list no longer includes mpd/rmpc
- [ ] `opencode.json` is gitignored and untracked
- [ ] `templates/` is documented in `001-repo-map.md`
- [ ] predator host module uses inline Fish abbreviations (no
      `operatorFishAbbrs` let binding, no `mkPredatorConfig`)
- [ ] aurelius imports `homeManager.attic-client`
- [ ] All structure validation gates pass
- [ ] All three host evals succeed
- [ ] Predator drvPath unchanged from baseline (phases 1-4)
- [ ] No behavioral regressions on any host

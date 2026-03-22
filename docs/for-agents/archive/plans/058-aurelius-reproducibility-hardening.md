# 058 Aurelius Reproducibility Hardening

## Why this exists

The Aurelius work now has working runtime slices, but part of the operational
state was created ad hoc during debugging and validation. That is not good
enough for a NixOS repository.

This plan exists to eliminate the remaining non-reproducible state, reduce the
credential footprint, and make the post-debug runtime understandable and
repeatable.

## Findings frozen before execution

1. No tracked secret was found in the repo.
   - `./scripts/check-repo-public-safety.sh` passes.
   - Grep found no tracked PAT, registration token, Attic server secret, or
     private cache key material.

2. The GitHub runner token file is private, but currently duplicated.
   - It exists on the `aurelius`, which is required for the service.
   - It also exists on the local machine, which is not required for steady-state
     runner operation and increases exposure.

3. The GitHub runner org routing depends on non-Nix GitHub control-plane state.
   - Runner group `Default` had to be changed manually to permit public
     repositories.
   - The workflow shape that worked for org-wide execution was:
     `runs-on.group = "Default"` plus explicit labels.

4. The runner credential is broader than the minimum acceptable long-term
   posture.
   - The current PAT is sufficient for the job, but the final target should be
     the narrowest credential shape that keeps runner replacement reliable.

5. Some Aurelius-adjacent runtime state is still provisioned outside Nix.
   - GitHub runner token file on the host.
   - Attic server environment file on the host.
   - Attic publisher token files on hosts.
   - GitHub organization runner-group policy.

6. The repo currently documents pieces of this state, but does not yet provide a
   single canonical reproducibility workflow for rebuilding the full Aurelius
   service surface from scratch.

## Scope

In scope:
- GitHub runner reproducibility and credential hardening
- Attic reproducibility and secret material expectations
- Documentation and private example shape for repeatable recovery
- Explicit classification of what is:
  - tracked declarative state
  - private host state
  - external control-plane state

Out of scope:
- changing the overall product scope of Aurelius
- replacing GitHub org settings with something declarative that GitHub itself
  does not support

## Quality bar

1. No tracked file may contain real secrets, tokens, private endpoints, or live
   private key material.
2. Any required private host file must have:
   - one canonical path
   - one documented owner
   - one documented provisioning procedure
3. Any external control-plane dependency must be documented as such instead of
   being silently treated as “part of Nix”.
4. Runtime success does not count as reproducible unless a new operator can
   rebuild the state from:
   - tracked repo
   - gitignored private overrides
   - documented external setup steps
5. Credential scope must be intentionally minimized, not merely “working”.

## Execution plan

### Phase 1. Freeze and classify external state

1. Inventory every Aurelius-related dependency that lives outside tracked Nix:
   - GitHub org runner group policy
   - GitHub runner PAT/token file
   - Attic server env file
   - Attic publisher token files
2. Classify each one as:
   - external SaaS control-plane
   - private host secret
   - private local operator credential
3. Record the classification in one human-facing workflow doc.

### Phase 2. Remove unnecessary credential spread

1. Stop treating the local copy of the GitHub runner PAT as normal runtime
   state.
2. Decide the final source of truth for runner registration:
   - remote host token file only
   - or operator-managed credential that is copied during provisioning
3. Rotate the currently exposed PAT and replace it with a fresh credential.
4. If possible, tighten the credential shape:
   - prefer the narrowest PAT/permission model that still supports
     org-runner replacement.

### Phase 3. Codify GitHub runner reproducibility

1. Document the exact GitHub org settings required:
   - runner group visibility
   - public repository allowance
   - repository eligibility
2. Update the private example and human docs to reflect the org-wide runner
   shape, not the earlier repo-only shape.
3. Add an operator workflow doc for:
   - generating the credential
   - placing it on the correct host
   - applying the host
   - verifying registration
4. Record the proven workflow syntax for org-wide jobs:
   - `group: Default`
   - labels: `self-hosted`, `aurelius`, `nixos`, `aarch64`

### Phase 4. Codify Attic reproducibility

1. Document the exact secret files required for Attic:
   - server env file on `aurelius`
   - publisher token files on publishers
2. Define one canonical provisioning path for those files.
3. Ensure the docs distinguish clearly between:
   - Attic server declaration in Nix
   - private secret material on hosts
   - GitHub-/operator-driven bootstrap steps

### Phase 5. Add a recovery / rebuild runbook

1. Write one end-to-end runbook for rebuilding the Aurelius service surface from
   a fresh host:
   - tracked modules
   - private overrides
   - external GitHub setup
   - external token/secret placement
   - validation commands
2. Cover at least:
   - GitHub runner
   - Attic
   - Forgejo access model
   - Prometheus access model

## Definition of done

This plan is done only when all of the following are true:

1. The repo remains free of tracked secrets and public-safety gates pass.
2. Every required private file has one canonical documented path and one
   documented provisioning flow.
3. GitHub org runner behavior is documented precisely enough to be repeated for
   another repo in the org without trial-and-error.
4. The currently exposed PAT has been rotated and the final credential posture
   is explicitly documented.
5. A new operator can follow the runbook and rebuild the Aurelius service setup
   without relying on memory of this debugging session.

## Validation

- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- targeted runtime checks for:
  - `github-runner-aurelius.service`
  - Attic endpoint reachability
  - org-runner smoke on more than one repo in the org

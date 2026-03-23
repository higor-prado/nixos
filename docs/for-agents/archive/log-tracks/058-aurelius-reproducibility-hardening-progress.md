# Aurelius Reproducibility Hardening Progress

## Status

In progress

## Related Plan

- [058-aurelius-reproducibility-hardening.md](/home/higorprado/nixos/docs/for-agents/plans/058-aurelius-reproducibility-hardening.md)

## Findings frozen

- No tracked secret was found by the public-safety gate.
- The GitHub runner PAT is duplicated locally and remotely; only the remote copy
  is required for steady-state runner operation.
- GitHub org runner routing required control-plane settings outside Nix:
  - runner group public-repo allowance
  - explicit `group: Default` in workflow routing
- Attic and GitHub runner still depend on host-private token/env files.

## Executed so far

- Added a human runbook for bootstrap and recovery:
  - [107-aurelius-service-bootstrap.md](/home/higorprado/nixos/docs/for-humans/workflows/107-aurelius-service-bootstrap.md)
- Tightened the private-override docs so token file paths are described as
  target-host paths, not operator-host paths.
- Tightened the tracked Aurelius private example to reflect org/repo binding and
  target-host token semantics.
- Removed the unnecessary local copy of the GitHub runner PAT from `predator`.
- Rechecked runtime after that removal:
  - the remote token file still exists on `aurelius`
  - `github-runner-aurelius.service` remained `active`
- Rotated the runner PAT on `aurelius` and reapplied the host:
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
    passed
  - `github-runner-aurelius.service` remained `active`
  - the runner stayed connected and continued to report completed smoke jobs
- Revalidated:
  - `./scripts/check-docs-drift.sh`
  - `./scripts/check-repo-public-safety.sh`

## Remaining hardening work

- revoke the old exposed GitHub PAT in GitHub UI
- optionally remove stale runner entries left behind in GitHub UI from the
  earlier repo-scoped/manual experiments

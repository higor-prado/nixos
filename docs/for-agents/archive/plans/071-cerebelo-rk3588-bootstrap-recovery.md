# Cerebelo RK3588 Bootstrap Recovery Plan

## Goal

Recover `cerebelo` bootstrap on Orange Pi 5 by rebasing the host on the
official `gnull/nixos-rk3588` Orange Pi 5 support instead of continuing with a
generic nixpkgs-only RK3588 boot chain. The outcome is a reproducible NVMe boot
without microSD, using the repo's dendritic host composition only for
host-specific policy on top of the upstream board stack.

## Scope

In scope:
- inspect and align with the official Orange Pi 5 bootstrap model from
  `gnull/nixos-rk3588`
- add the upstream board stack to this repo's flake inputs if required
- redefine `cerebelo` so board boot/kernel/device-tree ownership comes from the
  official stack, while repo-specific policy stays in tracked host owners
- validate the generated boot artifacts against the known-good SD image shape
- reprovision the NVMe from the corrected host definition
- document the exact preflight gates required before asking for another
  microSD-removal test

Out of scope:
- further blind physical reboot testing before the preflight gates in this plan
  pass
- GPU/NPU/display feature enablement beyond what is already required for the
  board to boot correctly
- redesigning the repo's general host architecture
- migrating secrets or changing private override ownership

## Why This Plan Exists

The current `070-cerebelo-host-setup.md` assumed that a generic nixpkgs-based
RK3588 host plus `extlinux` and a DTB override would be sufficient. The actual
runtime evidence disproved that assumption:
- the SD image boots reliably
- repeated NVMe boots without microSD failed
- earlier fixes changed `/boot` layout, UUIDs, and kernel params without proving
  that the official Orange Pi 5 board stack had been preserved

This plan replaces that incorrect bootstrap assumption with the upstream model
the board is already known to boot.

## Current State

- The repo has an active but now unreliable bootstrap plan at
  [070-cerebelo-host-setup.md](/home/higorprado/nixos/docs/for-agents/plans/070-cerebelo-host-setup.md).
- There are active investigation notes at:
  - [070-cerebelo-agent-handoff.md](/home/higorprado/nixos/docs/for-agents/current/070-cerebelo-agent-handoff.md)
  - [070-cerebelo-boot-loader-analysis.md](/home/higorprado/nixos/docs/for-agents/current/070-cerebelo-boot-loader-analysis.md)
  - [071-cerebelo-upstream-bootstrap-contract.md](/home/higorprado/nixos/docs/for-agents/current/071-cerebelo-upstream-bootstrap-contract.md)
- The SD image is the only known-good runtime baseline for this board.
- The SD baseline on `192.168.1.X` is confirmed to boot with the official
  `nixos-rk3588` U-Boot shape:
  - `/boot/extlinux/extlinux.conf`
  - `/boot/nixos/*`
  - kernel `6.1.115`
  - DTB under `device-tree-overlays`
- The repo's current `cerebelo` host does not yet import an official
  `nixos-rk3588` Orange Pi 5 base.
- `flake.nix` currently has no `nixos-rk3588` input.
- The tracked files
  [default.nix](/home/higorprado/nixos/hardware/cerebelo/default.nix) and
  [hardware-configuration.nix](/home/higorprado/nixos/hardware/cerebelo/hardware-configuration.nix)
  contain exploratory bootstrap changes that are not yet evidence-backed.
- The git worktree is dirty:
  - modified `flake.lock`
  - modified `hardware/cerebelo/*.nix`
  - untracked active docs under `docs/for-agents/current/`
  - untracked helper scripts under `scripts/`
- Private overrides exist for `cerebelo`, but they are out of scope for tracked
  planning and must not be read or copied into tracked docs.

## Desired End State

- `cerebelo` boot/kernel/device-tree ownership comes from the official Orange Pi
  5 stack, not from local guesswork.
- Repo-specific behavior remains limited to:
  - hostname
  - SSH/user policy
  - shell/editor/tooling
  - zram and server tuning
  - `/data` mount
- The generated boot artifacts for NVMe match the supported Orange Pi 5 shape in
  all material ways.
- The next no-microSD test is requested only after explicit preflight evidence
  exists for:
  - upstream board stack integration
  - correct boot artifact generation
  - correct root/boot device references
  - SSH/user/data configuration present in the target closure

## Phases

### Phase 0: Freeze The Bootstrap Contract

Targets:
- [flake.nix](/home/higorprado/nixos/flake.nix)
- [070-cerebelo-host-setup.md](/home/higorprado/nixos/docs/for-agents/plans/070-cerebelo-host-setup.md)
- [070-cerebelo-agent-handoff.md](/home/higorprado/nixos/docs/for-agents/current/070-cerebelo-agent-handoff.md)
- [070-cerebelo-boot-loader-analysis.md](/home/higorprado/nixos/docs/for-agents/current/070-cerebelo-boot-loader-analysis.md)

Changes:
- inspect the official `gnull/nixos-rk3588` Orange Pi 5 definitions and record:
  - which flake output or module owns the board
  - which boot artifacts it expects
  - which kernel/device-tree artifacts differ from generic nixpkgs output
- record which assumptions in `070-cerebelo-host-setup.md` are now invalid
- do not change the board again until that contract is written down

Validation:
- a short current-log note exists describing the exact upstream integration point
- [071-cerebelo-upstream-bootstrap-contract.md](/home/higorprado/nixos/docs/for-agents/current/071-cerebelo-upstream-bootstrap-contract.md)
  records the frozen upstream contract and the invalidated assumptions
- no new physical boot test is requested during this phase

Diff expectation:
- docs-only clarification of the supported board stack and invalidated
  assumptions

Commit target:
- `docs(cerebelo): freeze rk3588 bootstrap contract`

### Phase 1: Rebase Host Definition On The Official Board Stack

Targets:
- [flake.nix](/home/higorprado/nixos/flake.nix)
- [modules/hosts/cerebelo.nix](/home/higorprado/nixos/modules/hosts/cerebelo.nix)
- [default.nix](/home/higorprado/nixos/hardware/cerebelo/default.nix)
- [hardware-configuration.nix](/home/higorprado/nixos/hardware/cerebelo/hardware-configuration.nix)
- [performance.nix](/home/higorprado/nixos/hardware/cerebelo/performance.nix)

Changes:
- add the upstream `nixos-rk3588` flake input if needed by the chosen
  integration path
- reduce local board ownership to only the facts that truly belong in this repo
- remove ad hoc bootstrap workarounds that duplicate or conflict with the
  official board stack
- keep `modules/hosts/cerebelo.nix` focused on host composition and operator
  policy, not low-level board emulation

Validation:
- `./scripts/run-validation-gates.sh cerebelo`
- a local eval proves the `cerebelo` host now depends on the official board
  stack rather than a generic DTB-only override

Diff expectation:
- `flake.nix` gains one upstream input
- `hardware/cerebelo/*` becomes thinner and more board-contract-driven
- `modules/hosts/cerebelo.nix` keeps only host composition concerns

Commit target:
- `refactor(cerebelo): rebase host on official rk3588 board stack`

### Phase 2: Prove Boot Artifact Shape Before Touching Hardware Again

Targets:
- local eval/build outputs for `cerebelo`
- generated boot metadata and closure paths

Changes:
- generate the corrected `cerebelo` system closure locally
- compare its boot artifact shape against the known-good SD image baseline:
  - extlinux location
  - kernel/initrd naming
  - DTB/device-tree overlay ownership
  - root and boot references

Validation:
- `./scripts/run-validation-gates.sh cerebelo`
- targeted eval/build commands for the `cerebelo` closure
- if evaluated Nix behavior changed materially, run a closure comparison against
  the last local baseline

Diff expectation:
- no repo-path changes required if the rebase already generated the correct
  shape; otherwise, small follow-up tracked fixes only

Commit target:
- `fix(cerebelo): align generated boot artifacts with official opi5 shape`

### Phase 3: Reprovision NVMe From The Corrected Definition

Targets:
- NVMe layout and installed system on `cerebelo`
- remote checkout at `/home/rk/nixos-config`

Changes:
- sync the corrected repo state to `cerebelo`
- reprovision the NVMe from the corrected `cerebelo` definition
- inspect the installed boot artifacts offline from the SD-booted rescue
  environment

Validation:
- mounted NVMe shows the expected boot files in the expected locations
- installed closure contains:
  - correct root/boot references
  - `higorprado`
  - SSH keys
  - `/data` mount
- no further physical test is requested until this offline inspection passes

Diff expectation:
- no new tracked repo diff unless a concrete mismatch is discovered

Commit target:
- no commit in this phase unless tracked files must change again

### Phase 4: Controlled No-microSD Acceptance Test

Targets:
- physical Orange Pi 5 boot without microSD
- network reachability and SSH

Changes:
- only after phases 0–3 pass, request one new physical test without microSD

Validation:
- host reaches the network
- SSH works as `higorprado`
- `findmnt -n -o SOURCE /` shows the NVMe root
- `/data` mounts
- the runtime hostname is `cerebelo`

Diff expectation:
- none if the acceptance test passes

Commit target:
- `fix(cerebelo): complete rk3588 nvme bootstrap`

## Risks

- The official board stack may require a different integration shape than a
  simple host import.
- The existing dirty worktree may contain exploratory changes that obscure which
  behavior came from tracked code versus manual remote edits.
- If the corrected upstream-based stack still fails, the next trustworthy signal
  will be serial/U-Boot logs, not more filesystem guessing.
- Repeated manual remote changes without a frozen contract will reintroduce
  drift between repo state and the installed NVMe.

## Definition of Done

- `cerebelo` is defined on top of the official Orange Pi 5 upstream stack.
- The repo clearly separates board bootstrap ownership from repo-specific host
  policy.
- The NVMe install is reprovisioned from that corrected definition.
- One no-microSD test passes with SSH reachability and expected mounts.
- The superseded assumptions in `070-cerebelo-host-setup.md` are either updated
  or explicitly retired.

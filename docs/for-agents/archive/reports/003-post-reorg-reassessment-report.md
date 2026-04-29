# Post-Reorganization Reassessment Report

## Status

Completed

## Scope

Reassess the package-ownership refactor after the recent changes, using the current working tree and the reported `aurelius` failure, and answer a narrower question:

- which changes still make sense,
- which changes are technically wrong,
- which changes are philosophically wrong for this repo,
- and what should be corrected next.

No code changes were made for this report.

## Inputs reviewed

- `modules/features/shell/core-user-packages.nix`
- `modules/features/dev/dev-tools.nix`
- `modules/features/shell/tui-tools.nix`
- `modules/features/system/packages-server-tools.nix`
- `modules/features/system/attic-client.nix`
- `modules/features/system/podman.nix`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`
- `hardware/predator/default.nix`
- `hardware/predator/packages.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- `docs/for-agents/current/001-home-vs-system-package-placement-report.md`
- `docs/for-agents/current/002-home-vs-system-package-reorganization-progress.md`

## Executive summary

The refactor improved the repo in important ways, but it is **not fully correct yet**.

### What is clearly better now

- package ownership is much more aligned with machine-owner vs user-owner
- package policy was removed from `hardware/predator/`
- `allowUnfree` was removed from `hardware/predator/hardware/gpu-nvidia.nix`
- `packages-docs-tools` and `packages-toolchains` moved to Home Manager, which fits their real owner much better
- `podman` was correctly split into system runtime vs user workflow (`distrobox`)
- `predator-tui` moved to HM, which matches its real owner better

### What is still wrong now

The biggest remaining problem is this:

> `homeManager.packages-server-tools` duplicates packages that are already owned by other Home Manager feature owners.

That produced the real failure you saw on `aurelius`:

- `core-user-packages` already owns `programs.btop`
- `packages-server-tools` now also adds `btop`
- both end up in the same HM profile
- `buildEnv` rejects the duplicate `bin/btop`

This is not just one accidental collision. It reveals a broader design mistake in the current `homeManager.packages-server-tools` split.

## Reassessment of each major change

## 1. `packages-docs-tools` → Home Manager

File:
- `modules/features/dev/packages-docs-tools.nix`

Current state:
- `ghostscript`
- `tectonic`
- `mermaid-cli`
- `pandoc`

Assessment:
- technically correct
- philosophically correct

Reason:
- these are user workflow tools
- they do not configure machine runtime
- they fit the repo rule very well

Verdict:
- **keep as-is**

## 2. `packages-toolchains` → Home Manager

File:
- `modules/features/dev/packages-toolchains.nix`

Current state:
- package list moved to `home.packages`
- Fish path setup remains in the same HM owner

Assessment:
- technically correct
- philosophically correct

Reason:
- these are user dev tools
- the same owner already carries user-shell behavior
- the resulting owner is more coherent than before

Verdict:
- **keep as-is**

## 3. `podman` split into NixOS + Home Manager

File:
- `modules/features/system/podman.nix`

Current state:
- NixOS owner enables Podman runtime
- HM owner adds `distrobox`

Assessment:
- technically correct
- philosophically correct

Reason:
- Podman is machine/runtime capability
- Distrobox is user/operator workflow
- the split matches the repo model exactly

Verdict:
- **keep as-is**

## 4. `attic-client` moved to Home Manager

File:
- `modules/features/system/attic-client.nix`

Current state:
- HM installs `attic-client`
- NixOS publisher/service logic already references required binaries directly where needed

Assessment:
- technically acceptable
- philosophically acceptable

Reason:
- the module behaves like operator CLI availability, not machine capability
- the service owners already keep direct runtime references where needed

Caveat:
- host selection may still need review for operational consistency, but the ownership direction itself is fine

Verdict:
- **keep as-is for now**

## 5. Predator hardware package policy cleanup

Files:
- `hardware/predator/default.nix`
- `hardware/predator/packages.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- `modules/hosts/predator.nix`

Current state:
- `hardware/predator/default.nix` no longer imports `./packages.nix`
- `hardware/predator/packages.nix` is now inert/empty
- `gpu-nvidia.nix` no longer sets `allowUnfree`
- `tpm2-tools` is host-owned in NixOS
- `nvtopPackages.nvidia` is host-owned in HM

Assessment:
- mostly correct

Reason:
- moving package policy out of `hardware/` is correct
- moving `allowUnfree` out of hardware is correct
- `tpm2-tools` in the host owner is reasonable
- `nvtopPackages.nvidia` in HM is reasonable

Caveat:
- `hardware/predator/packages.nix` is now dead weight and should eventually be removed, not preserved as an empty file

Verdict:
- **direction is correct**
- **small cleanup still desirable**

## The major technical failure: `homeManager.packages-server-tools`

File:
- `modules/features/system/packages-server-tools.nix`

Current state:

### NixOS side
- `lsof`
- `strace`
- `bind`
- `mtr`
- `iperf3`
- `tcpdump`

### HM side
- `eza`
- `bat`
- `fd`
- `ripgrep`
- `jq`
- `yq-go`
- `tmux`
- `btop`
- `ncdu`

## Why the current HM side is technically wrong

Several items are already owned elsewhere in HM:

- `btop` — already owned by `modules/features/shell/core-user-packages.nix` via `programs.btop`
- `ripgrep` — already owned by `modules/features/shell/core-user-packages.nix`
- `bat` — already owned by `modules/features/dev/dev-tools.nix` via `programs.bat`
- `eza` — already owned by `modules/features/dev/dev-tools.nix` via `programs.eza`
- `fd` — already owned by `modules/features/dev/dev-tools.nix`
- `jq` — already owned by `modules/features/dev/dev-tools.nix`
- `tmux` — already owned by `modules/features/shell/terminal-tmux.nix` via `programs.tmux`

That means the new HM bundle is not just “server-oriented interactive tooling”. It is re-declaring user capabilities that already have canonical owners.

The reported `aurelius` failure is the first concrete proof of that problem.

## Why the current HM side is philosophically wrong

It violates the repo’s own ownership style in a subtler way:

- `core-user-packages`, `dev-tools`, and `terminal-tmux` are already named after concrete user-facing capabilities
- `homeManager.packages-server-tools` re-bundles parts of those capabilities under a role-flavored bucket
- this makes ownership less obvious, not more obvious

In repo terms, the problem is not “server-specific imports are forbidden”.
The problem is:

> the new HM bundle is not a clean owner; it is an overlapping bundle that steals package ownership from existing canonical feature owners.

That is exactly the kind of thing that creates ambiguity again after the cleanup.

## What would still be valid inside a server-oriented HM bundle

A server-oriented HM bundle could still exist, but it should only keep packages that are:

- truly interactive/operator-facing
- not already canonically owned by another imported HM feature
- genuinely server-ops flavored rather than generic shell/dev UX

From the current list, the clearest survivor is:
- `ncdu`

Possibly also:
- `yq-go`

Everything else on the current HM list is already better owned elsewhere in this repo.

## Host-by-host reassessment

## `aurelius`

Current relevant HM imports:
- `homeManager.core-user-packages`
- `homeManager.monitoring-tools`
- `homeManager.packages-server-tools`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`

Assessment:
- technically broken today because of overlap in the HM profile
- philosophically noisier than before because multiple HM owners claim the same tools

Verdict:
- **needs correction before the reorg can be considered sound**

## `cerebelo`

Current relevant HM imports:
- `homeManager.core-user-packages`
- `homeManager.packages-server-tools`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`
- `homeManager.podman`

Assessment:
- likely exposed to the same overlap problem as `aurelius`
- whether it has already failed or not is secondary; the ownership shape is still wrong

Verdict:
- **needs the same correction path as `aurelius`**

## `predator`

Current relevant HM imports do **not** include `homeManager.packages-server-tools`

Assessment:
- the current Predator-specific changes still make sense
- Predator is not the source of the `packages-server-tools` overlap issue

Verdict:
- **mostly fine in current state**

## Final judgment on the refactor so far

## Changes that still make sense and should remain

- move `packages-docs-tools` to HM
- move `packages-toolchains` to HM
- split `podman`
- move `attic-client` to HM
- move `predator-tui` to HM
- remove package policy from `hardware/predator/`
- remove `allowUnfree` from `hardware/predator/hardware/gpu-nvidia.nix`
- keep `tpm2-tools` in the Predator host owner
- keep `nvtopPackages.nvidia` in Predator HM user ownership

## Change that is conceptually right in direction but wrong in current implementation

- split `packages-server-tools`

The NixOS half is fine.
The HM half is not.

## What is wrong technically right now

1. `homeManager.packages-server-tools` duplicates packages already owned by other HM features.
2. That duplication can produce real buildEnv collisions, as seen with `btop` on `aurelius`.
3. Even where it does not immediately fail, it still makes the ownership graph unclear.

## What is wrong philosophically right now

1. The HM server-tools split reintroduces ambiguity by bundling generic user tooling under a role bucket.
2. It weakens canonical ownership by making existing HM owners non-authoritative.
3. It partially undoes the clarity the refactor was trying to create.

## Recommended correction direction

Without editing anything in this report, the correction direction should be:

1. Keep the **NixOS half** of `packages-server-tools`.
2. Shrink or remove the **HM half** so it contains only tools not already owned elsewhere.
3. Prefer existing canonical HM owners for these tools:
   - `core-user-packages`
   - `dev-tools`
   - `terminal-tmux`
4. Remove duplicated HM package declarations before claiming the refactor is complete.
5. Optionally delete `hardware/predator/packages.nix` once the code correction phase starts.

## Bottom line

The initial reorganization was **directionally good**, but one part is now clearly wrong:

> `homeManager.packages-server-tools` is overlapping with existing HM feature owners and is both technically unsafe and philosophically inconsistent with the repo’s ownership model.

So the honest current assessment is:

- the refactor should **not** be rolled back wholesale
- most of it should be kept
- but `packages-server-tools` needs a corrective pass before the repo can be considered clean again

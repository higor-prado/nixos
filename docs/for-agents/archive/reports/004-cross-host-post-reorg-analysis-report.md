# Cross-Host Post-Reorganization Analysis Report

## Status

Completed

## Goal

Reassess the package-ownership reorganization against the actual operating model of this repository and answer the stricter question:

- does the new ownership shape make sense across **all tracked hosts**,
- is it correct both **technically** and **architecturally**,
- and which parts should be kept versus corrected.

This report is analysis only. No code changes were made while producing it.

## Method

Read the current tracked owners involved in the reorganization, focusing on the concrete host composition model used by this repo:

- feature owners under `modules/features/**`
- concrete host owners under `modules/hosts/*.nix`
- Predator hardware owners under `hardware/predator/**`
- the earlier analysis and progress reports under `docs/for-agents/current/`

The analysis uses the repo’s documented operating model:

- `modules/features/**` own reusable behavior
- `modules/hosts/*.nix` own concrete host composition
- `hardware/<host>/` owns hardware support only
- Home Manager is wired explicitly by each host
- package ownership should follow **machine owner vs user owner**

## Current repo-specific decision rule

For this repo, the correct question is not merely “is this package CLI or GUI?”
The correct question is:

> who is the real owner of this capability in the dendritic runtime surface?

That leads to this repo-specific rule:

### NixOS owner when

A package or setting belongs to the machine runtime because it:

- enables or supports a system service
- is part of boot, kernel, drivers, PAM, firewall, networking, containers, `/etc`, or system users/groups
- must exist independently of any user home
- is admin/runtime support for the host as a machine

### Home Manager owner when

A package or setting belongs to the tracked user environment because it:

- is used interactively by the tracked user
- is part of shell/editor/desktop/operator workflow
- is configured under HM program owners, `home.packages`, `home.file`, `xdg.configFile`, `systemd.user`, or session variables
- represents a user choice rather than machine capability

### Split owner when

One capability spans both concerns, for example:

- daemon + client UX
- runtime substrate + user config
- machine container runtime + user container workflow

This repo already uses that split pattern successfully in several places.

## The repo operating model that matters for this reassessment

The important architectural fact is that this repo is **host-composed, not role-generated**.

Concrete hosts explicitly choose which lower-level modules they import:

- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`

That means a package-owner decision must satisfy two constraints at once:

1. the owner itself must be coherent
2. the owner must stay coherent when combined with the other explicit imports of each host

This second constraint is the one that exposed the current problem.

A module may look reasonable in isolation and still be wrong for this repo if, once imported into real hosts, it overlaps with other canonical owners.

## Reassessment of the reorganization

## 1. Changes that remain correct across all hosts

### 1.1 `packages-docs-tools` moved to Home Manager

File:
- `modules/features/dev/packages-docs-tools.nix`

Current owner shape:
- `flake.modules.homeManager.packages-docs-tools`
- installs `ghostscript`, `tectonic`, `mermaid-cli`, `pandoc`

Assessment:
- technically correct
- architecturally correct
- cross-host safe

Reasoning:
- these are interactive workflow tools
- they are not machine-runtime requirements
- they do not duplicate a more canonical existing HM program owner
- they remain explicit in host HM imports

Conclusion:
- this change should stay

### 1.2 `packages-toolchains` moved to Home Manager

File:
- `modules/features/dev/packages-toolchains.nix`

Current owner shape:
- `flake.modules.homeManager.packages-toolchains`
- installs `gcc`, `nodejs`, `sqlite`, `tree-sitter`, `binutils`, `gnumake`, `cmake`, `libtool`
- also owns related Fish path setup

Assessment:
- technically correct
- architecturally correct
- cross-host safe

Reasoning:
- this owner now groups user dev toolchains plus user shell adjustments
- that is a more coherent owner than the previous NixOS bundle
- the tools are part of user development workflow, not machine capability
- no conflicting canonical HM owner already claims this exact set

Conclusion:
- this change should stay

### 1.3 `podman` split into NixOS runtime + HM workflow

File:
- `modules/features/system/podman.nix`

Current owner shape:
- `nixos.podman` enables the machine runtime
- `homeManager.podman` installs `distrobox`

Assessment:
- technically correct
- architecturally correct
- cross-host safe

Reasoning:
- this follows the repo’s successful split-feature pattern
- Podman runtime is machine-owned
- Distrobox is user/operator workflow
- explicit host composition remains clear

Conclusion:
- this change should stay

### 1.4 `attic-client` moved to Home Manager

File:
- `modules/features/system/attic-client.nix`

Current owner shape:
- `homeManager.attic-client` installs `attic-client`

Assessment:
- technically acceptable
- architecturally acceptable
- cross-host acceptable

Reasoning:
- the machine-owned Attic service/publisher modules already use explicit binary references where needed
- the exported package behaves like operator CLI availability
- that makes HM ownership reasonable

Caveat:
- host selection should remain explicit and intentional
- whether every host should import `homeManager.attic-client` is an operational decision, not an ownership contradiction

Conclusion:
- the ownership direction is correct
- host selection can be revisited separately if desired

### 1.5 Predator hardware package-policy cleanup

Files:
- `hardware/predator/default.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- `hardware/predator/packages.nix`
- `modules/hosts/predator.nix`

Current shape:
- `hardware/predator/default.nix` no longer imports `./packages.nix`
- `gpu-nvidia.nix` no longer sets `nixpkgs.config.allowUnfree`
- Predator-specific packages are now owned in the concrete host owner / HM user owner

Assessment:
- architecturally correct direction
- technically acceptable after the `allowUnfree` regression fix

Reasoning:
- package policy no longer lives in `hardware/`
- `allowUnfree` moved back under policy ownership where the repo says it belongs
- Predator-specific tooling is now owned either by the host machine owner (`tpm2-tools`) or the user owner (`predator-tui`, `nvtopPackages.nvidia`)

Caveat:
- `hardware/predator/packages.nix` is now dead tracked residue and should eventually be removed rather than kept as an inert file

Conclusion:
- the cleanup direction is correct
- one small follow-up cleanup remains optional

## 2. The key failure: `homeManager.packages-server-tools`

File:
- `modules/features/system/packages-server-tools.nix`

Current shape:

### NixOS half
- `lsof`
- `strace`
- `bind`
- `mtr`
- `iperf3`
- `tcpdump`

### Home Manager half
- `eza`
- `bat`
- `fd`
- `ripgrep`
- `jq`
- `yq-go`
- `tmux`
- `btop`
- `ncdu`

The NixOS half is not the problem.
The Home Manager half is.

## Why this fails technically in this repo

This repo does not evaluate feature owners in isolation. It composes them concretely per host.

On real hosts, the HM side of `packages-server-tools` overlaps with existing canonical HM owners already imported by those hosts.

### Existing canonical HM owners already present elsewhere

#### `modules/features/shell/core-user-packages.nix`
Owns:
- `programs.btop`
- `ripgrep`
- plus other base CLI tools

#### `modules/features/dev/dev-tools.nix`
Owns:
- `programs.bat`
- `programs.eza`
- `fd`
- `jq`

#### `modules/features/shell/terminal-tmux.nix`
Owns:
- `programs.tmux`

That means `homeManager.packages-server-tools` is currently claiming packages that already belong to other HM owners.

### Concrete cross-host consequence

This is not hypothetical. It already surfaced on a tracked host.

On `aurelius`, the HM profile combines:
- `homeManager.core-user-packages`
- `homeManager.packages-server-tools`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`

That produced a real `buildEnv` conflict for:
- `btop`

Because:
- one owner already exported `btop`
- the new HM server-tools owner exported `btop` again
- both landed in the same HM profile

So the issue is not just “aurelius has one package conflict”.
The issue is:

> the new HM server-tools owner is structurally unsafe because it overlaps with canonical HM owners that are already imported on real hosts.

## Why this fails philosophically in this repo

The repo’s architecture wants narrow, canonical owners named after concrete user-facing capabilities.

Examples of good HM owners already present:
- `core-user-packages`
- `dev-tools`
- `terminal-tmux`
- `git-gh`
- `terminals`

The current HM half of `packages-server-tools` cuts across those owners and re-bundles their packages into a looser role-flavored bucket.

That is philosophically wrong for this repo because it makes ownership less obvious, not more obvious.

Instead of:
- “`btop` belongs to the base shell/user package owner”
- “`bat` and `eza` belong to dev/operator CLI ergonomics”
- “`tmux` belongs to terminal-tmux”

we get:
- “these also belong to a server-tools bundle sometimes”

That is precisely the kind of ownership blur the refactor was supposed to remove.

## 3. Host-by-host reassessment

## 3.1 `predator`

Current relevant HM imports:
- `homeManager.core-user-packages`
- `homeManager.docker`
- `homeManager.podman`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`
- `homeManager.packages-docs-tools`
- `homeManager.packages-toolchains`
- no `homeManager.packages-server-tools`

Assessment:
- the current Predator-specific reorganization is mostly coherent
- Predator is not currently affected by the HM server-tools overlap because it does not import that owner

Technical verdict:
- mostly sound

Architectural verdict:
- mostly sound

Notes:
- `predator-tui` in HM is a good fit
- `nvtopPackages.nvidia` in HM is a good fit
- `tpm2-tools` in the host NixOS owner is a defensible fit

## 3.2 `aurelius`

Current relevant HM imports:
- `homeManager.core-user-packages`
- `homeManager.git-gh`
- `homeManager.monitoring-tools`
- `homeManager.packages-server-tools`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`

Assessment:
- currently technically unsound
- architecturally unsound

Technical reason:
- explicit duplicate/overlapping ownership in one HM profile
- already manifested as a real `btop` collision

Architectural reason:
- multiple HM owners are claiming the same interactive tools
- canonical ownership is no longer obvious

Verdict:
- current `aurelius` shape proves the HM server-tools owner is wrong

## 3.3 `cerebelo`

Current relevant HM imports:
- `homeManager.core-user-packages`
- `homeManager.git-gh`
- `homeManager.packages-server-tools`
- `homeManager.dev-tools`
- `homeManager.terminal-tmux`
- `homeManager.podman`

Assessment:
- same architectural problem as `aurelius`
- likely same class of technical overlap even if not yet surfaced in exactly the same failure mode

Technical reason:
- overlapping HM owners for the same packages remain present

Architectural reason:
- same re-bundling of already-owned HM capabilities under a role bucket

Verdict:
- the current shape is also wrong for `cerebelo`, even if `aurelius` exposed it first

## 4. What this means for the refactor as a whole

The reorganization should not be judged as all-good or all-bad.
The honest conclusion is mixed:

### Good and should remain
- docs/toolchains to HM
- `podman` split
- `attic-client` to HM
- Predator package-policy cleanup
- moving user-facing tools out of hardware owners

### Wrong and must be corrected
- the current Home Manager half of `packages-server-tools`

This is the single largest point where the refactor currently fails the repo’s standards.

## 5. Cross-host design rule that emerges from this failure

A package-bundle refactor in this repo must satisfy an extra rule beyond “system vs home”:

> a Home Manager owner must not re-claim packages already canonically owned by other imported HM owners on real hosts.

That is the real lesson from the `aurelius` failure.

A bundle can be philosophically correct in machine-vs-user terms and still be wrong in this repo if it overlaps with more canonical HM owners.

## 6. Correction direction consistent with the repo

The correction should follow the repo’s actual operating model:

1. preserve explicit host composition
2. preserve canonical lower-level owners
3. avoid role bundles that duplicate existing user-capability owners
4. keep the NixOS half of `packages-server-tools` if desired
5. reduce or remove the HM half unless it contains only tools that are not already canonically owned elsewhere

### Concretely

The NixOS half is defensible because it represents machine/admin diagnostics.

The HM half should be reconsidered under this standard:
- if a package already belongs to `core-user-packages`, `dev-tools`, or `terminal-tmux`, it should stay there
- a remaining HM server-ops owner, if any, should only contain packages that are:
  - interactive/operator-facing
  - not already owned elsewhere
  - genuinely server-ops-specific rather than generic user tooling

## 7. Final judgment

### Technically across all hosts

The current reorganization is:
- **mostly correct** in its broad direction
- **not yet technically sound** because `homeManager.packages-server-tools` introduces overlapping HM ownership and already breaks `aurelius`

### Philosophically across all hosts

The current reorganization is:
- **better than the original state** in most areas
- **not yet philosophically clean** because the HM server-tools bundle undermines canonical ownership already present in other HM feature owners

## 8. Bottom line

If the standard is “must make sense in all hosts, technically and philosophically,” then the honest answer is:

> most of the reorganization is good and should stay, but the current Home Manager half of `packages-server-tools` does not meet the repo’s standards and must be corrected before the refactor can be considered sound.

That is the central conclusion of this reassessment.

# Hardware Boundary Cleanup

## Goal

Make `hardware/` mean what it says: machine-specific hardware, boot, disk, and
storage-reset concerns only. Move software/package/policy fragments out of that
tree when they do not describe the machine itself.

## Audit Summary

### Keep in `hardware/`

These files are correctly placed because they describe the machine, the boot
chain, the disk layout, or storage state tightly coupled to that host:

- `hardware/predator/hardware-configuration.nix`
- `hardware/predator/disko.nix`
- `hardware/predator/boot.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- `hardware/predator/hardware/laptop-acer.nix`
- `hardware/predator/hardware/peripherals-logi.nix`
- `hardware/predator/hardware/audio-pipewire.nix`
- `hardware/predator/hardware/encryption.nix`
- `hardware/predator/impermanence.nix`
- `hardware/predator/root-reset.nix`
- `hardware/predator/_persistence-inventory.nix`
- `hardware/aurelius/hardware-configuration.nix`
- `hardware/aurelius/disko.nix`

Rationale:
- disk topology, bootloader/initrd behavior, persistence layout, and device
  enablement are machine-owned concerns
- `_persistence-inventory.nix` is not generic tooling metadata; it is data owned
  by the predator persistence layout
- predator's device-specific helper files remain under `hardware/` because they
  are tied to concrete attached or integrated hardware quirks, not generic
  host policy

### Wrongly placed in `hardware/`

These files are host-specific, but they are not hardware:

- `hardware/predator/overlays.nix`
- `hardware/predator/packages.nix`
- `hardware/predator/performance.nix`
- `hardware/aurelius/default.nix` (partially)
- `hardware/aurelius/performance.nix`

Rationale:
- `overlays.nix` is package patch/workaround policy, not machine description
- `packages.nix` is software selection, even if chosen because of hardware
- `performance.nix` is system policy/tuning, not hardware topology
- `hardware/aurelius/default.nix` mixes correct hardware/boot imports with
  non-hardware runtime policy (`system.stateVersion`)

## Desired End State

- `hardware/` contains only machine-specific hardware, boot, disk, encryption,
  persistence, and reset/state files
- host-specific software policy lives outside `hardware/`
- no new generic “host runtime bucket” is invented just to move the mess
- host files remain explicit and readable

## Placement Rules

1. If a file describes devices, firmware, boot, storage topology, encryption,
   or persistence/reset tied to that host, it stays in `hardware/<host>/`.
2. If a file changes package evaluation (`nixpkgs.overlays`), it does not belong
   in `hardware/`, even if only one host imports it.
3. If a file only adds packages or tuning/policy (`environment.systemPackages`,
   sysctl, zram, ananicy, daemon scheduling), it does not belong in `hardware/`.
4. Host-specific software/policy should move to host-owned runtime modules under
   `modules/hosts/`, not to a new generic bucket.

## Refactor Direction

### 1. Move predator package/policy files out of `hardware/`

Targets:
- `hardware/predator/overlays.nix`
- `hardware/predator/packages.nix`
- `hardware/predator/performance.nix`
- `modules/hosts/predator.nix`

Preferred shape:
- create narrowly named host-owned modules adjacent to the host composition,
  for example:
  - `modules/hosts/predator-nixpkgs-overlays.nix`
  - `modules/hosts/predator-packages.nix`
  - `modules/hosts/predator-performance.nix`

Why this shape:
- keeps the ownership host-specific
- stops pretending package policy is hardware
- avoids inventing a new bucket like `modules/host-runtime/`

### 2. Move aurelius performance out of `hardware/`

Targets:
- `hardware/aurelius/default.nix`
- `hardware/aurelius/performance.nix`
- `modules/hosts/aurelius.nix`

Preferred shape:
- `modules/hosts/aurelius-performance.nix`
- move `system.stateVersion` out of `hardware/aurelius/default.nix` and into
  the concrete host composition or a narrow host-owned runtime file

### 3. Keep predator persistence/reset where it is

Targets:
- `hardware/predator/impermanence.nix`
- `hardware/predator/root-reset.nix`
- `hardware/predator/_persistence-inventory.nix`

Decision:
- do not move these

Why:
- they are tightly coupled to the predator disk layout and initrd behavior
- moving them out would obscure the machine/storage relationship rather than
  clarify it

### 4. Keep hardware-quirk helpers under `hardware/`

Targets:
- `hardware/predator/hardware/laptop-acer.nix`
- `hardware/predator/hardware/peripherals-logi.nix`
- `hardware/predator/hardware/audio-pipewire.nix`

Decision:
- keep them where they are

Why:
- `laptop-acer.nix` is ACPI/platform-profile/kernel-module behavior for the
  concrete Acer machine
- `peripherals-logi.nix` is udev/service/device handling for the actual
  attached Logitech peripherals
- `audio-pipewire.nix` is a host/device-specific HDMI audio quirk workaround
  keyed to the concrete card/node behavior
### 5. Tighten docs

Targets:
- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-humans/02-structure.md`

Changes:
- stop saying `hardware/<name>/` contains generic “overlays” or “packages”
- explicitly document that host-specific software policy belongs in host-owned
  modules, not in `hardware/`

## Validation

After each slice:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Final:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`

## Definition of Done

- no software-package-policy file remains under `hardware/`
- `hardware/` contains only machine-owned hardware/boot/disk/persistence files
- host-specific policy remains explicit and local to the host
- no new generic bucket is introduced

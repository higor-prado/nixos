# Dendritic Migration Guardrails

## Purpose

This file exists to stop agents from "making it work" in ways that violate the
dendritic pattern or leave the repo with framework-shaped local glue.

Use this while working on the `dendritic-without-den` migration.

## Non-Negotiable Shape

1. Every non-entry-point Nix file remains a top-level module.
2. Lower-level NixOS and Home Manager modules are published as values on the
   top-level config, typically under `flake.modules.*`.
3. Concrete configurations are declared explicitly as top-level values, such as
   `configurations.nixos.<host>.module`.
4. Host modules own host composition.
5. User modules own user composition.

## What "Good" Looks Like Here

- A host file declares its own `configurations.nixos.<host>.module`.
- A user file may publish:
  - `flake.modules.nixos.<user>`
  - `flake.modules.homeManager.<user>`
- A reusable feature file may publish:
  - `flake.modules.nixos.<feature>`
  - `flake.modules.homeManager.<feature>`
- Host-specific deltas are expressed in the host module.
- User-specific deltas are expressed in the user module.
- Shared reusable behavior lives in feature modules.

## What Must Not Happen

- Do not reintroduce a generic host generator.
  Bad examples:
  - `lib.mapAttrs` over inventory to synthesize all hosts
  - helper factories like `mkShadowHostModule`, `mkShadowHomeModule`
- Do not invent new option surfaces just to thread host deltas around.
  Bad examples:
  - `options.custom.fish.hostAbbreviationOverrides`
  - `options.custom.ssh.settings`
- Do not move ugly `lib.mkOption` declarations from one file to another and call
  that a migration.
- Do not create a repo-local mini-framework that hides composition behind helper
  functions.
- Do not use inventory feature selectors as a substitute for host composition.
- Do not optimize for deduplication if it makes the shape less dendritic.

## Decision Rule

When choosing where a piece of config belongs, prefer this order:

1. If it is specific to one host, put it in that host module.
2. If it is specific to one user, put it in that user module.
3. If it is truly shared across multiple hosts/users, publish it as a reusable
   lower-level module from the feature owner.
4. Only introduce a new option contract if there is a real reusable interface
   that cannot be expressed more directly.

## Practical Rule For This Repo

For this migration, the local runtime should stay boring:

- `modules/options/` may define the top-level runtime surface and shared
  lower-level contracts.
- `modules/hosts/` should declare concrete shadow configurations.
- `modules/users/` should declare concrete user lower-level modules.
- `modules/features/` should publish only shared reusable lower-level modules.

If a change makes the runtime feel more like a framework, stop and simplify it.

## Validation Standard

After each meaningful slice:

1. validate the relevant `flake.dendritic.nixosConfigurations.*` outputs
2. run `./scripts/run-validation-gates.sh`
3. update the active progress log with what changed and why the shape is still
   dendritic

Do not call a change an improvement unless it reduces structural distortion, not
just build errors.

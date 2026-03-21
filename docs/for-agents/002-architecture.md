# Architecture

Authoritative architecture for the tracked repo.

## Top-Level Runtime

The repo uses the dendritic pattern on top of `flake-parts`.

- `flake.nix` evaluates `inputs.flake-parts.lib.mkFlake` and auto-imports
  `./modules` through `import-tree`.
- Every tracked non-entry-point Nix file under `modules/` is a top-level module.
- Lower-level NixOS and Home Manager modules are published as top-level values,
  not imported through `specialArgs` or hidden helper frameworks.

## Core Runtime Surfaces

The canonical runtime is built from these top-level option surfaces:

- `username`: repo-wide tracked user identity
- `flake.modules.nixos.<name>`: published lower-level NixOS modules
- `flake.modules.homeManager.<name>`: published lower-level Home Manager modules
- `configurations.nixos.<name>.module`: concrete host configurations

Concrete `nixosConfigurations` are materialized in
`modules/nixos.nix` from
`configurations.nixos.<name>.module`.

## Concrete Host Composition

Each tracked host file also declares one concrete configuration at
`configurations.nixos.<name>.module`.

That module owns:

- the host's NixOS `imports`
- the host's Home Manager `imports`
- `networking.hostName`
- host-scoped package additions such as `environment.systemPackages`
- host-operator overlays that only make sense on that machine, such as
  machine-specific Fish abbreviations

Example shape:

```nix
  configurations.nixos.predator.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
      hardwareImports = [ ../../hardware/predator/default.nix ];
  in
  {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      nixos.system-base
      nixos.fish
    ] ++ hardwareImports;

    home-manager.users.${userName} = {
      imports = [
        homeManager.higorprado
        homeManager.fish
      ];
    };
  };
```

Concrete host composition is explicit on purpose. The host file is where the
repo says what that machine actually is.

Keep runtime-only payload local to the host file when it is not inventory-like.
Examples:

- hardware module import lists
- host-only `environment.systemPackages`
- operator-only Fish abbreviations

## Feature Modules

`modules/features/<category>/<name>.nix` owns reusable behavior.

Feature files publish lower-level modules such as:

```nix
flake.modules.nixos.my-feature = { pkgs, ... }: { ... };
flake.modules.homeManager.my-feature = { config, ... }: { ... };
```

Rules:

- publish NixOS config only when the feature has NixOS behavior
- publish Home Manager config only when the feature has HM behavior
- keep feature ownership narrow and user-facing
- declare custom options only in the narrow owner that actually consumes them

## User Modules

`modules/users/<name>.nix` owns the tracked user's base account and base Home
Manager module.

The current pattern is:

- `username` stores the repo-wide tracked user identity needed by host
  composition
- `modules/users/higorprado.nix` owns that identity fact in this repo
- `flake.modules.nixos.<name>` declares the NixOS user account
- `flake.modules.homeManager.<name>` declares the base HM user module
- repo-wide primary-user semantics such as admin groups belong here, not in
  host hardware files or generic shell features
- host-specific device/service entitlements for that user belong in the
  concrete host module, not in the shared user owner

This keeps user ownership out of host hardware files and out of generic feature
modules.

## Host-Aware Lower-Level Modules

Host-aware lower-level modules should stay explicit.

Use one of these patterns:

- capture direct flake inputs in the owning top-level module, for example
  `{ inputs, ... }: { flake.modules.homeManager.foo = { pkgs, ... }: ...; }`
- derive system-specific local packages inside the lower-level module from
  `pkgs` plus those captured `inputs`
- read narrow top-level facts from the owning module, for example
  `config.username`
- read existing lower-level state such as `config.networking.hostName`,
  `config.home.username`, or `osConfig`

Do not build a generic runtime carrier such as `repo.context` just to move
host/user payload around.

## Auto-Import and File Layout

Auto-import is provided by `import-tree`.

- tracked `modules/**/*.nix` files are auto-imported
- files prefixed with `_` are skipped and may hold data/helpers for the adjacent
  owner
- file paths name features and runtime surfaces; they do not encode module class

## What To Avoid

- no `specialArgs` / `extraSpecialArgs` pass-through
- no generic host generator that hides real host composition
- no inventory-driven feature toggles that replace explicit host imports
- no repo-local mini-framework around the runtime
- no host-aware logic smuggled through bare `{ host }:` lambdas in module lists

## Reading Order

When understanding the repo, read in this order:

1. `flake.nix`
2. `modules/nixos.nix`, `modules/flake-parts.nix`, and `modules/users/higorprado.nix`
3. `modules/hosts/<name>.nix`
4. `modules/users/<name>.nix`
5. `modules/features/**` and `modules/desktops/**`

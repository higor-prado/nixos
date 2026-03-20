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

- `repo.hosts.<name>`: tracked host inventory
- `repo.users.<name>`: tracked user inventory
- `flake.modules.nixos.<name>`: published lower-level NixOS modules
- `flake.modules.homeManager.<name>`: published lower-level Home Manager modules
- `configurations.nixos.<name>.module`: concrete host configurations

Concrete `nixosConfigurations` are materialized in
`modules/options/configurations-nixos.nix` from
`configurations.nixos.<name>.module`.

## Host Inventory

`modules/hosts/<name>.nix` owns the tracked inventory for each host:

```nix
repo.hosts.predator = {
  system = "x86_64-linux";
  role = "desktop";
  trackedUsers = [ "higorprado" ];
};
```

Inventory is data, not composition glue. It exists so concrete host modules can
read tracked facts from `config.repo.hosts.<name>`.

## Concrete Host Composition

Each tracked host file also declares one concrete configuration at
`configurations.nixos.<name>.module`.

That module owns:

- the host's NixOS `imports`
- the host's Home Manager `imports`
- `networking.hostName`
- concrete `repo.context` values for NixOS and Home Manager
- host-scoped package additions such as `environment.systemPackages`
- host-operator overlays that only make sense on that machine, such as
  machine-specific Fish abbreviations

Example shape:

```nix
configurations.nixos.predator.module =
  let
    hostInventory = config.repo.hosts.predator;
    host = hostInventory // {
      inherit inputs customPkgs;
    };
    user = config.repo.users.higorprado;
    hardwareImports = [ ../../hardware/predator/default.nix ];
    repoContext = {
      inherit host user;
      hostName = "predator";
      userName = user.userName;
    };
  in
  {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      config.flake.modules.nixos.repo-runtime-contracts
      config.flake.modules.nixos.repo-context
      config.flake.modules.nixos.system-base
      config.flake.modules.nixos.fish
    ] ++ hardwareImports;

    home-manager.users.${user.userName} = {
      imports = [
        config.flake.modules.homeManager.repo-context
        config.flake.modules.homeManager.higorprado
        config.flake.modules.homeManager.fish
      ];

      repo.context = repoContext;
    };

    repo.context = repoContext;
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

- `repo.users.<name>` stores tracked user facts
- `flake.modules.nixos.<name>` declares the NixOS user account
- `flake.modules.homeManager.<name>` declares the base HM user module
- repo-wide primary-user semantics such as admin groups belong here, not in
  host hardware files or generic shell features
- host-specific device/service entitlements for that user belong in the
  concrete host module, not in the shared user owner

This keeps user ownership out of host hardware files and out of generic feature
modules.

## Runtime Context

Host-aware lower-level modules read runtime facts from `config.repo.context.*`.

`repo.context.host` is the runtime host context assembled in the concrete host
module. It may extend tracked inventory with local runtime payload such as
`inputs` or `customPkgs` when reusable lower-level modules need those values.

The shared contract is published in
`modules/options/repo-runtime-contracts.nix`:

- `repo.context.hostName`
- `repo.context.host`
- `repo.context.userName`
- `repo.context.user`

Use this instead of `specialArgs`, `extraSpecialArgs`, or ad hoc host lambdas.

Examples:

- `config.repo.context.host.customPkgs`
- `config.repo.context.host.llmAgents`
- `config.repo.context.userName`

## Universal Runtime Contracts

`modules/options/repo-runtime-contracts.nix` also owns the narrow runtime
contracts that need to exist everywhere:

- `custom.host.role`
- `custom.user.name` as a compatibility bridge for private/legacy lower-level
  wiring
- shared Home Manager modules such as Catppuccin wiring

These are repo runtime contracts, not a feature-selection mechanism.

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
2. `modules/options/*.nix`
3. `modules/hosts/<name>.nix`
4. `modules/users/<name>.nix`
5. `modules/features/**` and `modules/desktops/**`

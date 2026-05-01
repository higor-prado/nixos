{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nixos-rk3588 = {
      url = "github:gnull/nixos-rk3588";
      # pre-commit-hooks is nixos-rk3588's internal dev tooling; we don't use it.
      # Override to suppress stale lock entries that produce
      # "override for a non-existent input" warnings.
      inputs.pre-commit-hooks.follows = "";
    };

    import-tree.url = "github:vic/import-tree";

    # impermanence uses its own nixpkgs/home-manager; no follows.
    impermanence = {
      url = "github:nix-community/impermanence";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
    };

    catppuccin-zen-browser-src = {
      url = "github:catppuccin/zen-browser";
      flake = false;
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    keyrs = {
      url = "github:higorprado/keyrs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waypaper-src = {
      url = "github:anufrievroman/waypaper/2.8";
      flake = false;
    };

    rmpc = {
      url = "github:mierak/rmpc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}

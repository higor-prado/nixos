{ inputs, lib, ... }:
{
  flake.modules.homeManager.llm-agents =
    { pkgs, ... }:
    let
      llmAgentsPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      omp = llmAgentsPkgs.omp.overrideAttrs (
        old:
        let
          existingRustFlags = if old ? env && old.env ? RUSTFLAGS then old.env.RUSTFLAGS else "";
          glimmerScannerRustFlags = lib.concatStringsSep " " [
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_create"
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_destroy"
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_reset"
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_scan"
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_serialize"
            "-Clink-arg=-Wl,-u,tree_sitter_glimmer_external_scanner_deserialize"
          ];
        in
        {
          env = (old.env or { }) // {
            RUSTFLAGS = lib.concatStringsSep " " (
              lib.filter (flag: flag != "") [
                existingRustFlags
                glimmerScannerRustFlags
              ]
            );
          };
        }
      );
    in
    {
      home.packages = [
        llmAgentsPkgs.claude-code
        llmAgentsPkgs.codex
        llmAgentsPkgs.crush
        llmAgentsPkgs.kilocode-cli
        llmAgentsPkgs.opencode
        llmAgentsPkgs.copilot-cli
        omp
        llmAgentsPkgs.pi
      ];
    };
}

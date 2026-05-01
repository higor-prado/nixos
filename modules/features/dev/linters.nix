{ ... }:
{
  flake.modules.homeManager.linters =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nixfmt
        yamllint
        sqlfluff
        hadolint
        mypy
        rubocop
        shellcheck
        golangci-lint
        ktlint
        tflint
        terraform-ls
        zls
      ];
    };
}

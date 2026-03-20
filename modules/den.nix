# Den flake module - aspect-oriented configuration framework.
{ inputs, ... }:
{
  imports = [
    "${inputs.den.outPath}/modules/aspects.nix"
    "${inputs.den.outPath}/modules/aspects/defaults.nix"
    "${inputs.den.outPath}/modules/aspects/definition.nix"
    "${inputs.den.outPath}/modules/aspects/provides.nix"
    "${inputs.den.outPath}/modules/context/host.nix"
    "${inputs.den.outPath}/modules/context/perHost-perUser.nix"
    "${inputs.den.outPath}/modules/context/user.nix"
    "${inputs.den.outPath}/modules/lib.nix"
    "${inputs.den.outPath}/modules/options.nix"
    "${inputs.den.outPath}/modules/output.nix"
  ];
}

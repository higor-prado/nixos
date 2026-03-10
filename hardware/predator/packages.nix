{
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    # NVIDIA GPU monitoring
    pkgs.nvtopPackages.nvidia
    # TPM2 tools for Predator laptop
    pkgs.tpm2-tools
  ];
}

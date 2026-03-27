{ inputs, ... }:
let
  upstreamNixpkgs = inputs.nixos-rk3588.inputs.nixpkgs;
  pkgsKernel = import upstreamNixpkgs { system = "aarch64-linux"; };
in
{
  flake.modules.nixos.rk3588-orangepi5 =
    { lib, ... }:
    {
      imports = [
        inputs.nixos-rk3588.nixosModules.boards.orangepi5.core
      ];

      _module.args.rk3588 = {
        inherit pkgsKernel;
        nixpkgs = upstreamNixpkgs;
      };

      # dtb-install.nix in the core module requires this in its function
      # signature but does not use it on extlinux systems.
      _module.args.nixos-generators = null;

      boot.loader = {
        grub.enable = lib.mkForce false;
        generic-extlinux-compatible.enable = lib.mkForce true;
      };

      # The core module sets overlays = []; add the two overlays required for
      # NVMe M.2 and I2C on Orange Pi 5.  These are copied from the official
      # sd-image/orangepi5.nix which is not imported here (it targets SD image
      # builds, not installed NVMe systems).
      hardware.deviceTree.overlays = [
        {
          name = "orangepi5-sata-overlay";
          dtsText = ''
            // Orange Pi 5 Pcie M.2 to sata
            /dts-v1/;
            /plugin/;

            / {
              compatible = "rockchip,rk3588s-orangepi-5";

              fragment@0 {
                target = <&sata0>;

                __overlay__ {
                  status = "disabled";
                };
              };

              fragment@1 {
                target = <&pcie2x1l2>;

                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "orangepi5-i2c-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "rockchip,rk3588s-orangepi-5";

              fragment@0 {
                target = <&i2c1>;

                __overlay__ {
                  status = "okay";
                  pinctrl-names = "default";
                  pinctrl-0 = <&i2c1m2_xfer>;
                };
              };
            };
          '';
        }
      ];
    };
}

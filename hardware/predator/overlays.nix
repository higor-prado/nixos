{ ... }:
{
  nixpkgs.overlays = [
    # Upstream dsearch currently installs its user unit with executable bits.
    # systemd warns for executable unit files under /etc/systemd/user.
    (_: prev: {
      dsearch = prev.dsearch.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          if [ -f "$out/lib/systemd/user/dsearch.service" ]; then
            chmod 0644 "$out/lib/systemd/user/dsearch.service"
          fi
          if [ -f "$out/share/systemd/user/dsearch.service" ]; then
            chmod 0644 "$out/share/systemd/user/dsearch.service"
          fi
        '';
      });
    })
    (_: prev: {
      # nixpkgs currently ships a 39-angle-patchdir patch that targets the wrong
      # file path during patchPhase. Keep Electron 39 on the updated nixpkgs,
      # but rewrite the patch config before patchPhase runs.
      electron_39 = prev.electron_39.override {
        "electron-unwrapped" = prev.electron_39.unwrapped.overrideAttrs (old: {
          patches = builtins.filter (
            patch: !(prev.lib.hasSuffix "/39-angle-patchdir.patch" (toString patch))
          ) old.patches;
          prePatch = (old.prePatch or "") + ''
            substituteInPlace electron/patches/config.json \
              --replace-fail '"repo": "src/third_party/angle/src"' '"repo": "src/third_party/angle"'
          '';
        });
      };
    })
  ];
}

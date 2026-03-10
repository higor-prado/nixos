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
  ];
}

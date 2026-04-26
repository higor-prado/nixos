{ pkgs }:

let
  flavor = "mocha";
  accent = "lavender";
  gtkSize = "standard";
in
{
  # Raw constants
  inherit flavor accent gtkSize;

  # Derived GTK theme
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ accent ];
    variant = flavor;
    size = gtkSize;
  };
  gtkThemeName = "catppuccin-${flavor}-${accent}-${gtkSize}";

  # Shared cursor theme (session + greeter)
  cursorTheme = {
    name = "phinger-cursors";
    package = pkgs.phinger-cursors;
  };

  # Icon theme (patched for waybar tray SVG colors)
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.runCommand "papirus-tray-patched" {} ''
      mkdir -p $out
      # Copy all contents from the original catppuccin-papirus-folders derivation
      cp -r ${pkgs.catppuccin-papirus-folders.override { flavor = flavor; accent = accent; }}/* $out/
      chmod -R +w $out

      LAVENDER="#b4befe"
      SRC="$out/share/icons/Papirus-Dark"

      declare -A SYMLINK_MAP=(
          ["nm-signal-00"]="16x16/symbolic/status/network-wireless-signal-none-symbolic.svg"
          ["nm-signal-25"]="16x16/symbolic/status/network-wireless-signal-weak-symbolic.svg"
          ["nm-signal-50"]="16x16/symbolic/status/network-wireless-signal-ok-symbolic.svg"
          ["nm-signal-75"]="16x16/symbolic/status/network-wireless-signal-good-symbolic.svg"
          ["nm-signal-100"]="16x16/symbolic/status/network-wireless-signal-excellent-symbolic.svg"
          ["nm-secure-signal-00"]="16x16/symbolic/status/network-wireless-signal-none-symbolic.svg"
          ["nm-secure-signal-25"]="16x16/symbolic/status/network-wireless-signal-weak-secure-symbolic.svg"
          ["nm-secure-signal-50"]="16x16/symbolic/status/network-wireless-signal-ok-secure-symbolic.svg"
          ["nm-secure-signal-75"]="16x16/symbolic/status/network-wireless-signal-good-secure-symbolic.svg"
          ["nm-secure-signal-100"]="16x16/symbolic/status/network-wireless-signal-excellent-secure-symbolic.svg"
          ["nm-no-connection"]="16x16/symbolic/status/network-wireless-disconnected-symbolic.svg"
          ["drive-removable-media-usb-panel"]="16x16/symbolic/devices/drive-removable-media-usb-symbolic.svg"
      )

      SIZES="16x16 16x16@2x 22x22 24x24 32x32 48x48"

      for size in $SIZES; do
          for panel_name in "''${!SYMLINK_MAP[@]}"; do
              symbolic_rel="''${SYMLINK_MAP[$panel_name]}"
              
              src_file="$SRC/''${size}/''${symbolic_rel#16x16/}"
              if [ ! -f "$src_file" ]; then
                  src_file="$SRC/$symbolic_rel"
              fi
              
              # Resolve the symlink inside the theme to get the real SVG
              if [ -L "$src_file" ]; then
                  real_src=$(readlink -f "$src_file")
              else
                  real_src="$src_file"
              fi

              if [ -f "$real_src" ]; then
                  mkdir -p "$SRC/''${size}/panel"
                  rm -f "$SRC/''${size}/panel/''${panel_name}.svg"
                  # Replace colors in SVG and save to the panel directory
                  sed -e "s/#dfdfdf/$LAVENDER/g" \
                      -e "s/#444444/$LAVENDER/g" \
                      "$real_src" > "$SRC/''${size}/panel/''${panel_name}.svg"
              fi
          done
      done
    '';
  };

  # Font
  font = {
    name = "JetBrains Mono Nerd Font";
    package = pkgs.nerd-fonts.jetbrains-mono;
  };
}

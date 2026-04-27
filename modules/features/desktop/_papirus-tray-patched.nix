{ pkgs, flavor, accent, accentHex }:

pkgs.runCommand "papirus-tray-patched" { } ''
  mkdir -p $out
  # Copy all contents from the original catppuccin-papirus-folders derivation
  cp -r ${pkgs.catppuccin-papirus-folders.override { inherit flavor accent; }}/* $out/
  chmod -R +w $out

  # Keep tray icons tinted to the shared theme accent in panel paths so Waybar
  # does not fall back to unfocused hardcoded colors after GTK menu interactions.
  TRAY_TINT="${accentHex}"
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

      # Blueman SNI IDs and tray icon alias used by waybar tray icon mapping.
      ["blueman"]="16x16/devices/bluetooth.svg"
      ["blueman-active"]="16x16/devices/bluetooth.svg"
      ["blueman-disabled"]="16x16/devices/bluetooth.svg"
      ["blueman-offline"]="16x16/devices/bluetooth.svg"
      ["blueman-tray"]="16x16/devices/bluetooth.svg"
      ["bluetooth-symbolic"]="16x16/devices/bluetooth.svg"
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
              dst="$SRC/''${size}/panel/''${panel_name}.svg"
              tmp=$(mktemp)
              # Replace colors in SVG and save through a temp file so in-place
              # panel icon patching does not truncate the source before sed reads it.
              sed -e "s/#dfdfdf/$TRAY_TINT/g" \
                  -e "s/#444444/$TRAY_TINT/g" \
                  "$real_src" > "$tmp"
              mv "$tmp" "$dst"
          fi
      done
  done
''

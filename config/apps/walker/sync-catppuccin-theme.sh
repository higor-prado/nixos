walker_theme_dir="$HOME/.config/walker/themes/$WALKER_THEME_NAME"

if [ ! -f "$WALKER_CATPPUCCIN_CSS" ] || [ ! -f "$WALKER_STYLE_TEMPLATE" ]; then
  echo "warning: syncWalkerCatppuccinTheme: missing source files" >&2
  exit 0
fi

$DRY_RUN_CMD mkdir -p "$walker_theme_dir"

if ! $DRY_RUN_CMD "$COREUTILS_INSTALL" -m 0644 "$WALKER_CATPPUCCIN_CSS" "$walker_theme_dir/catppuccin.css"; then
  echo "warning: syncWalkerCatppuccinTheme: failed to write catppuccin.css" >&2
fi

if ! $DRY_RUN_CMD "$GNU_SED_BIN" "s/@__ACCENT__/@$WALKER_ACCENT/g" "$WALKER_STYLE_TEMPLATE" > "$walker_theme_dir/style.css"; then
  echo "warning: syncWalkerCatppuccinTheme: failed to write style.css" >&2
fi

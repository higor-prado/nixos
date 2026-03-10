zen_profiles_ini="$HOME/.config/zen/profiles.ini"
theme_dir="$THEME_DIR"
logo_file="$LOGO_FILE"
pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

if [ ! -f "$zen_profiles_ini" ] || [ ! -d "$theme_dir" ]; then
  exit 0
fi

zen_profile_path="$("$GAWK_BIN" -F= '
  /^\[Profile/ { p=1; path=""; def=0; next }
  p && $1=="Path" { path=$2; next }
  p && $1=="Default" && $2=="1" { def=1; if (path != "") { print path; exit } }
  /^$/ { p=0 }
' "$zen_profiles_ini")"

if [ -z "$zen_profile_path" ]; then
  zen_profile_path="$("$GAWK_BIN" -F= '/^Path=/{print $2; exit}' "$zen_profiles_ini")"
fi

if [ -z "$zen_profile_path" ]; then
  exit 0
fi

zen_profile_dir="$HOME/.config/zen/$zen_profile_path"
zen_chrome_dir="$zen_profile_dir/chrome"
zen_user_js="$zen_profile_dir/user.js"

if [ ! -f "$theme_dir/userChrome.css" ] || [ ! -f "$theme_dir/userContent.css" ] || [ ! -f "$logo_file" ]; then
  echo "warning: syncZenCatppuccinTheme: missing files in $theme_dir" >&2
  exit 0
fi

$DRY_RUN_CMD mkdir -p "$zen_chrome_dir"
if ! $DRY_RUN_CMD "$COREUTILS_INSTALL" -m 0644 "$theme_dir/userChrome.css" "$zen_chrome_dir/userChrome.css"; then
  echo "warning: syncZenCatppuccinTheme: failed to write userChrome.css" >&2
fi
if ! $DRY_RUN_CMD "$COREUTILS_INSTALL" -m 0644 "$theme_dir/userContent.css" "$zen_chrome_dir/userContent.css"; then
  echo "warning: syncZenCatppuccinTheme: failed to write userContent.css" >&2
fi
if ! $DRY_RUN_CMD "$COREUTILS_INSTALL" -m 0644 "$logo_file" "$zen_chrome_dir/zen-logo.svg"; then
  echo "warning: syncZenCatppuccinTheme: failed to write zen-logo.svg" >&2
fi

if [ -f "$zen_user_js" ]; then
  if "$GNU_GREP_BIN" -q '^user_pref("toolkit\.legacyUserProfileCustomizations\.stylesheets",' "$zen_user_js"; then
    if ! $DRY_RUN_CMD "$GNU_SED_BIN" -i 's#^user_pref("toolkit\.legacyUserProfileCustomizations\.stylesheets".*#user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);#' "$zen_user_js"; then
      echo "warning: syncZenCatppuccinTheme: failed to patch toolkit pref in user.js" >&2
    fi
  else
    if ! $DRY_RUN_CMD "$COREUTILS_PRINTF" '\n%s\n' "$pref_line" >> "$zen_user_js"; then
      echo "warning: syncZenCatppuccinTheme: failed to append toolkit pref to user.js" >&2
    fi
  fi
else
  if ! $DRY_RUN_CMD "$COREUTILS_PRINTF" '%s\n' "$pref_line" > "$zen_user_js"; then
    echo "warning: syncZenCatppuccinTheme: failed to create user.js toolkit pref" >&2
  fi
fi

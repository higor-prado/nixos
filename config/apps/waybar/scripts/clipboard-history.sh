#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-1.rasi"
theme_args=()

if [ -f "$theme" ]; then
  theme_args=(
    -theme "$theme"
    -theme-str 'window { width: 900px; }'
    -theme-str 'mainbox { children: [ "inputbar", "listview" ]; spacing: 18px; padding: 20px; }'
    -theme-str 'inputbar { children: [ "textbox-prompt-colon", "entry" ]; }'
    -theme-str 'textbox-prompt-colon { enabled: true; expand: false; str: "󰅌"; padding: 15px 16px; border-radius: 12px; background-color: #B4BEFE26; text-color: #B4BEFEFF; }'
    -theme-str 'prompt { enabled: false; }'
    -theme-str 'entry { placeholder: "Search clipboard history"; }'
    -theme-str 'listview { columns: 1; lines: 10; fixed-height: false; fixed-columns: true; spacing: 10px; }'
    -theme-str 'element { orientation: horizontal; padding: 12px 16px; spacing: 10px; }'
    -theme-str 'element-text { horizontal-align: 0.0; vertical-align: 0.5; }'
  )
fi

selection="$(cliphist list | rofi -dmenu -i -p 'Clipboard' -mesg 'Select an entry to copy' "${theme_args[@]}")"
[ -n "${selection}" ] || exit 0

cliphist decode <<<"${selection}" | wl-copy

#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-1.rasi"
preview_script="$HOME/.config/waybar/scripts/clipboard-preview.sh"

theme_args=(
  -show-icons false
  -theme-str 'window { width: 700px; border-radius: 14px; }'
  -theme-str 'mainbox { children: [ "inputbar", "listview" ]; spacing: 10px; padding: 12px; }'
  -theme-str 'inputbar { spacing: 6px; padding: 8px 10px; }'
  -theme-str 'textbox-prompt-colon { enabled: true; expand: false; str: "󰅌"; padding: 7px 8px; border-radius: 10px; background-color: #B4BEFE26; text-color: #B4BEFEFF; }'
  -theme-str 'prompt { enabled: false; }'
  -theme-str 'entry { placeholder: "Search clipboard"; }'
  -theme-str 'listview { columns: 1; lines: 8; fixed-height: false; fixed-columns: true; spacing: 4px; }'
  -theme-str 'element { orientation: horizontal; children: [ "element-text" ]; padding: 10px 10px; spacing: 0px; border-radius: 10px; }'
  -theme-str 'element-icon { enabled: false; size: 0px; }'
  -theme-str 'element-text { horizontal-align: 0.0; vertical-align: 0.5; }'
)

if [ -f "$theme" ]; then
  theme_args=( -theme "$theme" "${theme_args[@]}" )
fi

mapfile -t entries < <(cliphist list)
[ "${#entries[@]}" -gt 0 ] || exit 0

build_rofi_rows() {
  local entry entry_id preview

  for entry in "${entries[@]}"; do
    entry_id="${entry%%$'\t'*}"
    preview="${entry#*$'\t'}"
    preview="${preview#"${preview%%[![:space:]]*}"}"
    printf '%s\0info\x1f%s\n' "$preview" "$entry_id"
  done
}

cleanup_preview() {
  if [ -f "$preview_script" ]; then
    bash "$preview_script" hide || true
  fi
}

trap cleanup_preview EXIT
cleanup_preview

if [ -f "$preview_script" ]; then
  first_id="${entries[0]%%$'\t'*}"
  ROFI_INFO="$first_id" bash "$preview_script" select || true
fi

selected_index="$(
  build_rofi_rows \
    | rofi \
        -dmenu \
        -i \
        -p 'Clipboard' \
        -format 'i' \
        -no-custom \
        -on-selection-changed "bash $preview_script select" \
        "${theme_args[@]}"
)"
[ -n "${selected_index}" ] || exit 0

selected_id="$(printf '%s' "${entries[${selected_index}]}" | cut -f1)"
printf '%s' "$selected_id" | cliphist decode | wl-copy

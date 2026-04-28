#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/launchers/type-3/style-1.rasi"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/rofi-icons-v2"
thumb_canvas=48
thumb_inner=34
mkdir -p "$cache_dir"

theme_args=(
  -show-icons true
  -theme-str 'window { width: 700px; border-radius: 14px; }'
  -theme-str 'mainbox { children: [ "inputbar", "listview" ]; spacing: 10px; padding: 12px; }'
  -theme-str 'inputbar { spacing: 6px; padding: 8px 10px; }'
  -theme-str 'textbox-prompt-colon { enabled: true; expand: false; str: "󰅌"; padding: 7px 8px; border-radius: 10px; background-color: #B4BEFE26; text-color: #B4BEFEFF; }'
  -theme-str 'prompt { enabled: false; }'
  -theme-str 'entry { placeholder: "Search clipboard"; }'
  -theme-str 'listview { columns: 1; lines: 8; fixed-height: false; fixed-columns: true; spacing: 4px; }'
  -theme-str 'element { orientation: horizontal; children: [ "element-icon", "element-text" ]; padding: 8px 10px; spacing: 10px; border-radius: 10px; }'
  -theme-str 'element-icon { size: 40px; border-radius: 10px; }'
  -theme-str 'element-text { horizontal-align: 0.0; vertical-align: 0.5; }'
)

if [ -f "$theme" ]; then
  theme_args=( -theme "$theme" "${theme_args[@]}" )
fi

mapfile -t entries < <(cliphist list)
[ "${#entries[@]}" -gt 0 ] || exit 0

build_image_thumbnail() {
  local entry_id="$1"
  local preview="$2"
  local source thumb mime

  case "$preview" in
    '[[ binary data '*']]' ) ;;
    * ) return 1 ;;
  esac

  thumb="$cache_dir/${entry_id}.png"
  if [ -s "$thumb" ]; then
    printf '%s\n' "$thumb"
    return 0
  fi

  source="$(mktemp "$cache_dir/.${entry_id}.source.XXXXXX")"
  if ! printf '%s' "$entry_id" | cliphist decode > "$source"; then
    rm -f "$source"
    return 1
  fi

  mime="$(file --brief --mime-type "$source")"
  case "$mime" in
    image/png|image/jpeg|image/gif|image/webp|image/bmp|image/svg+xml) ;;
    *)
      rm -f "$source"
      return 1
      ;;
  esac

  rm -f "$thumb"
  if ! magick "${source}[0]" -auto-orient \
    \( +clone -thumbnail "${thumb_canvas}x${thumb_canvas}^" -gravity center -extent "${thumb_canvas}x${thumb_canvas}" -blur 0x8 -brightness-contrast -18x-8 \) \
    \( +clone -thumbnail "${thumb_inner}x${thumb_inner}" \) \
    -delete 0 -gravity center -compose over -composite -strip "PNG32:${thumb}"; then
    rm -f "$source" "$thumb"
    return 1
  fi

  rm -f "$source"
  printf '%s\n' "$thumb"
}

build_rofi_rows() {
  local entry entry_id preview thumb

  for entry in "${entries[@]}"; do
    entry_id="${entry%%$'\t'*}"
    preview="${entry#*$'\t'}"
    preview="${preview#"${preview%%[![:space:]]*}"}"

    if thumb="$(build_image_thumbnail "$entry_id" "$preview")"; then
      printf '%s\0icon\x1f%s\n' "$preview" "$thumb"
    else
      printf '%s\n' "$preview"
    fi
  done
}

if [ "${1-}" = "--dump-rofi" ]; then
  build_rofi_rows
  exit 0
fi

selected_index="$(
  build_rofi_rows \
    | rofi -dmenu -i -p 'Clipboard' -format 'i' -no-custom "${theme_args[@]}"
)"
[ -n "${selected_index}" ] || exit 0

selected_id="$(printf '%s' "${entries[${selected_index}]}" | cut -f1)"
printf '%s' "$selected_id" | cliphist decode | wl-copy

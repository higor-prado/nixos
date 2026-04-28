#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}/cliphist-rofi-preview"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/preview-images"
current_file="$state_dir/current-image"
pid_file="$state_dir/window.pid"
mkdir -p "$state_dir" "$cache_dir"

decode_image() {
  local entry_id="$1"
  local existing source mime ext image

  existing="$(find "$cache_dir" -maxdepth 1 -type f -name "${entry_id}.*" | head -n1 || true)"
  if [ -n "$existing" ]; then
    printf '%s\n' "$existing"
    return 0
  fi

  source="$(mktemp "$cache_dir/.${entry_id}.source.XXXXXX")"
  if ! printf '%s' "$entry_id" | cliphist decode > "$source"; then
    rm -f "$source"
    return 1
  fi

  mime="$(file --brief --mime-type "$source")"
  case "$mime" in
    image/png) ext=png ;;
    image/jpeg) ext=jpg ;;
    image/gif) ext=gif ;;
    image/webp) ext=webp ;;
    image/bmp) ext=bmp ;;
    image/svg+xml) ext=svg ;;
    *)
      rm -f "$source"
      return 1
      ;;
  esac

  image="$cache_dir/${entry_id}.${ext}"
  mv "$source" "$image"
  printf '%s\n' "$image"
}

window_running() {
  [ -f "$pid_file" ] || return 1
  kill -0 "$(cat "$pid_file")" 2>/dev/null
}

spawn_window() {
  window_running && return 0

  kitty \
    --class clipboard-preview \
    --title 'Clipboard Preview' \
    --single-instance \
    --instance-group clipboard-preview \
    sh -lc '
      current_file="$1"
      last=""
      trap "exit 0" TERM INT
      while true; do
        current="$(cat "$current_file" 2>/dev/null || true)"
        if [ "$current" != "$last" ]; then
          clear
          if [ -n "$current" ] && [ -f "$current" ]; then
            kitten icat --clear --transfer-mode=memory "$current"
          else
            printf "\\n\\n  Clipboard image preview\\n"
          fi
          last="$current"
        fi
        sleep 0.15
      done
    ' sh "$current_file" >/dev/null 2>&1 &

  echo $! > "$pid_file"
}

hide_window() {
  : > "$current_file"
  if window_running; then
    kill "$(cat "$pid_file")" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}

case "${1-}" in
  select)
    entry_id="${ROFI_INFO-}"
    [ -n "$entry_id" ] || exit 0
    if image="$(decode_image "$entry_id")"; then
      printf '%s\n' "$image" > "$current_file"
      spawn_window
    else
      hide_window
    fi
    ;;
  hide)
    hide_window
    ;;
  *)
    echo "usage: $0 {select|hide}" >&2
    exit 2
    ;;
esac

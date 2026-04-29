#!/usr/bin/env bash
set -euo pipefail

mode="${1:-region}"
screenshot_dir="${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
timestamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$screenshot_dir"

case "$mode" in
  full)
    output="$screenshot_dir/screenshot-full-$timestamp.png"
    grim "$output"
    ;;
  region)
    output="$screenshot_dir/screenshot-region-$timestamp.png"
    geometry="$(slurp -c 'b4befeff')" || exit 0
    [ -n "$geometry" ] || exit 0
    grim -g "$geometry" "$output"
    ;;
  *)
    echo "usage: $0 [full|region]" >&2
    exit 2
    ;;
esac

wl-copy --type image/png <"$output"

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Screenshot saved" "$output"
fi

printf '%s\n' "$output"

#!/usr/bin/env bash
set -euo pipefail

raw="$(hyprctl activewindow 2>/dev/null || true)"
[ -n "$raw" ] || exit 0

class="$(printf '%s\n' "$raw" | sed -n 's/^class: //p' | head -n 1)"
title="$(printf '%s\n' "$raw" | sed -n 's/^title: //p' | head -n 1)"
[ -n "$class" ] || exit 0

lower_class="${class,,}"
lower_title="${title,,}"

trim() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

strip_suffixes() {
  local value="$1"
  shift
  local suffix
  for suffix in "$@"; do
    case "$value" in
      *"$suffix") value="${value%"$suffix"}" ;;
    esac
  done
  trim "$value"
}

strip_browser_title() {
  strip_suffixes "$1" \
    " — Mozilla Firefox" \
    " - Mozilla Firefox" \
    " — Firefox" \
    " - Firefox" \
    " — Zen Browser" \
    " - Zen Browser" \
    " — Floorp" \
    " - Floorp" \
    " — Google Chrome" \
    " - Google Chrome" \
    " — Chromium" \
    " - Chromium" \
    " — Brave" \
    " - Brave" \
    " — Vivaldi" \
    " - Vivaldi"
}

label=""
icon=""

case "$lower_class" in
  firefox*|zen*|floorp*|google-chrome|chromium|brave-browser|vivaldi|vivaldi-stable)
    browser_label="$(strip_browser_title "$title")"
    case "$lower_title" in
      *github*)
        icon="󰊤"
        label="${browser_label:-GitHub}"
        ;;
      *youtube*)
        icon="󰗃"
        label="${browser_label:-YouTube}"
        ;;
      *gmail*|*inbox*)
        icon="󰇮"
        label="${browser_label:-Mail}"
        ;;
    esac
    ;;
esac

if [ -z "$icon" ]; then
  case "$lower_class" in
    firefox*)
      icon="󰈹"
      label="$(strip_browser_title "$title")"
      label="${label:-Firefox}"
      ;;
    zen*)
      icon="󰈹"
      label="$(strip_browser_title "$title")"
      label="${label:-Zen}"
      ;;
    floorp*)
      icon="󰈹"
      label="$(strip_browser_title "$title")"
      label="${label:-Floorp}"
      ;;
    google-chrome|chromium)
      icon=""
      label="$(strip_browser_title "$title")"
      label="${label:-Chrome}"
      ;;
    brave-browser)
      icon=""
      label="$(strip_browser_title "$title")"
      label="${label:-Brave}"
      ;;
    vivaldi|vivaldi-stable)
      icon=""
      label="$(strip_browser_title "$title")"
      label="${label:-Vivaldi}"
      ;;
    code|code-url-handler|codium|vscodium)
      icon="󰨞"
      label="$(strip_suffixes "$title" " - Visual Studio Code" " — Visual Studio Code" " - VSCodium" " — VSCodium")"
      label="${label:-Code}"
      ;;
    cursor|cursor-url-handler)
      icon="󰨞"
      label="$(strip_suffixes "$title" " - Cursor" " — Cursor")"
      label="${label:-Cursor}"
      ;;
    zeditor|zed)
      icon="󰨞"
      label="$(trim "$title")"
      label="${label:-Zed}"
      ;;
    spotify)
      icon="󰓇"
      label="$(strip_suffixes "$title" " - Spotify Premium" " — Spotify Premium" " - Spotify" " — Spotify" "Spotify Premium" "Spotify Free" "Spotify")"
      label="${label:-Spotify}"
      ;;
    steam)
      icon="󰓓"
      label="$(strip_suffixes "$title" " - Steam" " — Steam" "Steam")"
      label="${label:-Steam}"
      ;;
    kitty)
      icon=""
      label="$(trim "$title")"
      label="${label:-Kitty}"
      ;;
    foot)
      icon=""
      label="$(trim "$title")"
      label="${label:-Foot}"
      ;;
    alacritty)
      icon=""
      label="$(trim "$title")"
      label="${label:-Alacritty}"
      ;;
    ghostty)
      icon=""
      label="$(trim "$title")"
      label="${label:-Ghostty}"
      ;;
    org.gnome.nautilus|nautilus)
      icon="󰪶"
      label="$(trim "$title")"
      label="${label:-Files}"
      ;;
    obsidian)
      icon="󱞁"
      label="$(trim "$title")"
      label="${label:-Obsidian}"
      ;;
    emacs)
      icon=""
      label="$(trim "$title")"
      label="${label:-Emacs}"
      ;;
    teams-for-linux)
      icon="󰊻"
      label="$(trim "$title")"
      label="${label:-Teams}"
      ;;
    org.telegram.desktop|telegramdesktop)
      icon=""
      label="$(trim "$title")"
      label="${label:-Telegram}"
      ;;
    org.pwmt.zathura|zathura)
      icon="󰈦"
      label="$(trim "$title")"
      label="${label:-Zathura}"
      ;;
    mpv|vlc)
      icon="󰕼"
      label="$(trim "$title")"
      label="${label:-Media}"
      ;;
    *)
      icon="󱂬"
      label="$(trim "${title:-$class}")"
      ;;
  esac
fi

printf '%s  %s\n' "$icon" "$label"

#!/usr/bin/env bash
set -euo pipefail

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

render_label() {
  local class="$1"
  local title="$2"
  local lower_class="${class,,}"
  local lower_title="${title,,}"
  local icon="󱂬"
  local label="$(trim "${title:-$class}")"

  case "$lower_title" in
    *youtube*)
      icon="󰗃"
      label="$(strip_browser_title "$title")"
      label="${label:-YouTube}"
      ;;
    *github*|*gitlab*)
      icon="󰊤"
      label="$(strip_browser_title "$title")"
      ;;
    *gmail*|*inbox*)
      icon="󰇮"
      label="$(strip_browser_title "$title")"
      label="${label:-Mail}"
      ;;
  esac

  if [ "$icon" = "󱂬" ]; then
    case "$lower_class" in
      firefox*)
        icon="󰈹"
        label="$(strip_browser_title "$title")"
        label="${label:-Firefox}"
        ;;
      zen*|floorp*)
        icon="󰈹"
        label="$(strip_browser_title "$title")"
        label="${label:-Browser}"
        ;;
      chromium-browser|chromium*|google-chrome*|brave-browser*|vivaldi*)
        icon=""
        label="$(strip_browser_title "$title")"
        label="${label:-Chromium}"
        ;;
      code|code-url-handler|codium|vscodium)
        icon="󰨞"
        label="$(strip_suffixes "$title" " - Visual Studio Code" " — Visual Studio Code" " - VSCodium" " — VSCodium")"
        label="${label:-Code}"
        ;;
      dev.zed.zed|zed|zeditor)
        icon="󰨞"
        label="$(trim "$title")"
        label="${label:-Zed}"
        ;;
      spotify)
        icon="󰓇"
        label="$(strip_suffixes "$title" "Spotify Premium" "Spotify Free" "Spotify" " - Spotify Premium" " — Spotify Premium" " - Spotify" " — Spotify")"
        label="${label:-Spotify}"
        ;;
      kitty|foot|alacritty|ghostty)
        icon=""
        label="$(trim "$title")"
        label="${label:-Terminal}"
        ;;
      nautilus|org.gnome.nautilus)
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
      steam)
        icon="󰓓"
        label="$(strip_suffixes "$title" " - Steam" " — Steam" "Steam")"
        label="${label:-Steam}"
        ;;
      electron)
        if [[ "$lower_title" == *teams* ]]; then
          icon="󰊻"
          label="$(trim "$title")"
          label="${label:-Teams}"
        fi
        ;;
      teams-for-linux)
        icon="󰊻"
        label="$(trim "$title")"
        label="${label:-Teams}"
        ;;
      telegramdesktop|org.telegram.desktop|telegram*)
        icon=""
        label="$(trim "$title")"
        label="${label:-Telegram}"
        ;;
      zathura|org.pwmt.zathura)
        icon="󰈦"
        label="$(trim "$title")"
        label="${label:-Zathura}"
        ;;
      mpv|vlc)
        icon="󰕼"
        label="$(trim "$title")"
        label="${label:-Media}"
        ;;
    esac
  fi

  printf '%s  %s\n' "$icon" "$label"
}

render_active_window() {
  local json class title
  json="${ACTIVEWINDOW_JSON:-$(hyprctl activewindow -j 2>/dev/null || echo '{}')}"
  class="$(printf '%s' "$json" | jq -r '.class // empty')"
  title="$(printf '%s' "$json" | jq -r '.title // empty')"
  [ -n "$class" ] || return 0
  render_label "$class" "$title"
}

if [ "${1:-}" = "--render-json" ]; then
  ACTIVEWINDOW_JSON="$(cat)"
  render_active_window
  exit 0
fi

socket_path="${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:?}/.socket2.sock"
current="$(render_active_window)"
printf '%s\n' "$current"
last="$current"

while true; do
  while IFS= read -r event; do
    case "$event" in
      activewindow*|activewindowv2*|openwindow*|closewindow*|movewindow*|workspace*|focusedmon*)
        current="$(render_active_window)"
        if [ "$current" != "$last" ]; then
          printf '%s\n' "$current"
          last="$current"
        fi
        ;;
    esac
  done < <(stdbuf -oL nc -U "$socket_path")
  sleep 0.2
  current="$(render_active_window)"
  if [ "$current" != "$last" ]; then
    printf '%s\n' "$current"
    last="$current"
  fi
done

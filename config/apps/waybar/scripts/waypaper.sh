#!/usr/bin/env bash
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waypaper.lock"
flock -n 9 || exec hyprctl dispatch focuswindow class:waypaper
waypaper
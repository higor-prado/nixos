#!/usr/bin/env bash

mkset() {
  local out="$1"
  shift
  printf '%s\n' "$@" | sed '/^$/d' | sort -u >"$out"
}

set_missing_entries() {
  local left_file="$1"
  local right_file="$2"
  comm -23 "$left_file" "$right_file" || true
}

set_extra_entries() {
  local left_file="$1"
  local right_file="$2"
  comm -13 "$left_file" "$right_file" || true
}

#!/usr/bin/env bash
# audit-nix-ld-usage.sh — audit which installed binaries use nix-ld.
set -eo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

scope="nix-ld-usage"
original_pwd="$PWD"
enter_repo_root "${BASH_SOURCE[0]}"

interpreter="${AUDIT_NIX_LD_INTERPRETER:-/lib64/ld-linux-x86-64.so.2}"
max_depth=6
max_files=15000
diff_mode=0

usage() {
  cat <<'EOF'
Usage:
  scripts/audit-nix-ld-usage.sh              scan and report installed binaries that use nix-ld
  scripts/audit-nix-ld-usage.sh --diff       scan, compare against cached baseline, show new items
  scripts/audit-nix-ld-usage.sh --help       show this help

The scan finds ELF binaries whose dynamic linker is /lib64/ld-linux-x86-64.so.2
and that on this host resolve to the nix-ld loader. Results are grouped by
origin (Zed, uv, Steam, etc.) so you can tell what depends on nix-ld.

Use --diff to track what changed since the last scan. The baseline is saved
to ~/.cache/nix-ld-audit/baseline.txt.
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --diff) diff_mode=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf '[%s] unknown argument: %s\n' "$scope" "$1" >&2; usage >&2; exit 2 ;;
  esac
done

for cmd in find file readelf; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_warn "$scope" "SKIPPED: required command not found: $cmd"
    exit 0
  fi
done

if command -v renice >/dev/null 2>&1; then
  renice -n 10 -p "$$" >/dev/null 2>&1 || true
fi
if command -v ionice >/dev/null 2>&1; then
  ionice -c3 -p "$$" >/dev/null 2>&1 || true
fi

home_real=""
if [[ -n "${HOME:-}" && -d "$HOME" ]]; then
  home_real="$(cd -- "$HOME" && pwd -P 2>/dev/null || true)"
fi

scan_roots=()
declare -A seen_roots

make_absolute() {
  local path="$1"
  if [[ "$path" == /* ]]; then printf '%s\n' "$path"
  else printf '%s/%s\n' "$original_pwd" "$path"
  fi
}

is_forbidden_root() {
  local root="$1"
  case "$root" in
    /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/nix|/nix/*|/proc|/proc/*|/run|/run/*|/sbin|/sys|/sys/*|/tmp|/usr|/usr/bin|/usr/lib|/usr/share|/var)
      return 0 ;;
  esac
  [[ -n "$home_real" && "$root" == "$home_real" ]]
}

is_nix_managed_path() {
  local root="$1"
  case "$root" in /nix/*|/run/current-system/*|/run/wrappers/*|/etc/profiles/*) return 0 ;; esac
  [[ -n "$home_real" && "$root" == "$home_real/.nix-profile"* ]]
}

add_root() {
  local requested="$1" source_kind="$2" absolute canonical
  [[ -n "$requested" ]] || return 0
  absolute="$(make_absolute "$requested")"
  [[ -d "$absolute" ]] || return 0
  canonical="$(cd -- "$absolute" && pwd -P 2>/dev/null || true)"
  [[ -n "$canonical" ]] || return 0
  is_forbidden_root "$canonical" && return 0
  [[ "$source_kind" == "path" ]] && is_nix_managed_path "$canonical" && return 0
  [[ ! -r "$canonical" || ! -x "$canonical" ]] && return 0
  [[ -n "${seen_roots[$canonical]+set}" ]] && return 0
  seen_roots[$canonical]=1
  scan_roots+=("$canonical")
}

add_path_roots() {
  local path_entries=() entry
  IFS=':' read -r -a path_entries <<<"${PATH:-}"
  for entry in "${path_entries[@]}"; do add_root "$entry" path; done
}

discover_exec_roots_under() {
  local base="$1" dir
  [[ -d "$base" ]] || return 0
  local canonical
  canonical="$(cd -- "$base" && pwd -P 2>/dev/null || true)"
  [[ -n "$canonical" && -r "$canonical" && -x "$canonical" ]] || return 0
  is_forbidden_root "$canonical" && return 0
  while IFS= read -r -d '' dir; do
    add_root "$dir" default
  done < <(find "$canonical" -xdev -maxdepth "$max_depth" -type d \
    \( -name bin -o -name .bin -o -name sbin -o -name libexec \
       -o -path '*/node_modules/.bin' -o -path '*/vendor/bin' \) \
    -print0 2>/dev/null || true)
}

add_path_roots
if [[ -n "${HOME:-}" ]]; then
  add_root "$HOME/.local/bin" default
  add_root "$HOME/bin" default
  discover_exec_roots_under "${XDG_DATA_HOME:-$HOME/.local/share}"
  discover_exec_roots_under "${XDG_CONFIG_HOME:-$HOME/.config}"
  discover_exec_roots_under "${XDG_CACHE_HOME:-$HOME/.cache}"
fi
add_root "/usr/local/bin" default
discover_exec_roots_under "/opt"

if [[ "${#scan_roots[@]}" -eq 0 ]]; then
  log_warn "$scope" "SKIPPED: no usable scan roots"
  exit 0
fi

# Derive owner from path — the first directory after a known content root.
# Works for any software without hardcoded names.
derive_owner() {
  local path="$1" rest owner
  # Priority: most specific first
  if [[ "$path" == *"/.local/bin/"* ]]; then
    printf 'user-bin\n'; return
  fi
  if [[ "$path" == *"/.local/share/"* ]]; then
    rest="${path#*/.local/share/}"; owner="${rest%%/*}"
    printf '%s\n' "$owner"; return
  fi
  if [[ "$path" == *"/.cache/"* ]]; then
    rest="${path#*/.cache/}"; owner="${rest%%/*}"
    printf '%s\n' "$owner"; return
  fi
  if [[ "$path" == *"/.config/"* ]]; then
    rest="${path#*/.config/}"; owner="${rest%%/*}"
    printf '%s\n' "$owner"; return
  fi
  if [[ "$path" == "/opt/"* ]]; then
    rest="${path#/opt/}"; owner="${rest%%/*}"
    printf '%s\n' "$owner"; return
  fi
  if [[ "$path" == "/usr/local/"* ]]; then
    printf 'usr-local\n'; return
  fi
  printf 'unknown\n'
}

# Check if a binary lives inside a chroot/runtime tree.
# Looks for evidence of a self-contained filesystem (usr/bin + usr/lib + etc)
# in the binary's ancestor directories — this is the standard FHS layout,
# indicating the binary ships its own full environment including ld-linux.
is_in_runtime_tree() {
  local bin="$1" dir
  dir="$(dirname "$bin")"
  while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
    if [[ -d "$dir/usr/bin" && -d "$dir/usr/lib" && -d "$dir/etc" ]]; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

runtime_tree_excluded=0
results=()        # array of "category|path"
findings=0

extract_interpreter() {
  local path="$1" line value=""
  while IFS= read -r line; do
    case "$line" in
      *"Requesting program interpreter:"*)
        value="${line##*: }"; value="${value%]}"; break ;;
    esac
  done < <(readelf -l -- "$path" 2>/dev/null || true)
  printf '%s\n' "$value"
}

is_host_nix_ld() {
  [[ -e "$interpreter" || -L "$interpreter" ]] || return 1
  local target
  target="$(readlink -f -- "$interpreter" 2>/dev/null || true)"
  [[ "$target" == *nix-ld* ]]
}

if ! is_host_nix_ld; then
  log_warn "$scope" "SKIPPED: nix-ld interpreter not found on this host"
  exit 0
fi

files_inspected=0
elf_candidates=0
partial=0
ignored_by_user=0

# Load user-defined ignore list
ignore_file="$REPO_ROOT/private/audit-nix-ld-usage-ignored.txt"
ignore_prefixes=()
if [[ -f "$ignore_file" && -r "$ignore_file" ]]; then
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}" # trim leading whitespace
    line="${line%"${line##*[![:space:]]}"}" # trim trailing whitespace
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    # Expand ~ to $HOME
    line="${line/#\~/$HOME}"
    ignore_prefixes+=("$line")
  done < "$ignore_file"
fi

# Drop scan roots entirely inside ignored prefixes — avoids find traversal
if [[ "${#ignore_prefixes[@]}" -gt 0 ]]; then
  filtered=()
  for root in "${scan_roots[@]}"; do
    skip=0
    for prefix in "${ignore_prefixes[@]}"; do
      if [[ "$root" == "$prefix"* ]]; then skip=1; break; fi
    done
    [[ "$skip" -eq 0 ]] && filtered+=("$root")
  done
  scan_roots=("${filtered[@]}")
fi

scan_root() {
  local root="$1" entry ftype interp cat_label
  while IFS= read -r -d '' entry; do

    for prefix in "${ignore_prefixes[@]}"; do
      if [[ "$entry" == "$prefix"* ]]; then
        ignored_by_user=$((ignored_by_user + 1))
        continue 2
      fi
    done

    (( files_inspected < max_files )) || { partial=1; break; }
    files_inspected=$((files_inspected + 1))

    ftype="$(file -Lb -- "$entry" 2>/dev/null || true)"
    [[ "$ftype" == ELF* ]] || continue
    elf_candidates=$((elf_candidates + 1))
    interp="$(extract_interpreter "$entry")"
    [[ "$interp" == "$interpreter" ]] || continue
    if is_in_runtime_tree "$entry"; then
      runtime_tree_excluded=$((runtime_tree_excluded + 1))
      continue
    fi
    cat_label="$(derive_owner "$entry")"
    results+=("$cat_label|$entry")
    findings=$((findings + 1))
  done < <(find "$root" -xdev -maxdepth "$max_depth" \( -type f -o -type l \) -print0 2>/dev/null || true)
}

for root in "${scan_roots[@]}"; do
  scan_root "$root"
  [[ "$partial" -eq 1 ]] && break
done

if [[ "$partial" -eq 1 ]]; then
  log_warn "$scope" "scan budget reached at $max_files files; result may be incomplete"
fi

# Sort results by category then path
if [[ "${#results[@]}" -gt 0 ]]; then
  mapfile -t results < <(printf '%s\n' "${results[@]}" | sort)
fi

# --- Output ---
# First: diff mode - compare against cached baseline
new_findings=0
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nix-ld-audit"
cache_file="$cache_dir/baseline.txt"

if [[ "$diff_mode" -eq 1 ]]; then
  if [[ -f "$cache_file" ]]; then
    mapfile -t baseline < "$cache_file"
    # Find new entries
    for line in "${results[@]}"; do
      found=0
      for b in "${baseline[@]}"; do
        [[ "$line" == "$b" ]] && { found=1; break; }
      done
      if [[ "$found" -eq 0 ]]; then
        if [[ "$new_findings" -eq 0 ]]; then
          printf '[%s] === NEW SINCE LAST SCAN ===\n' "$scope"
        fi
        cat_label="${line%%|*}"
        path="${line#*|}"
        printf '[%s]   %s  %s\n' "$scope" "$cat_label" "$path"
        new_findings=$((new_findings + 1))
      fi
    done
    if [[ "$new_findings" -eq 0 ]]; then
      printf '[%s] nothing new since last scan\n' "$scope"
    fi
  else
    printf '[%s] no baseline found; run without --diff to create one\n' "$scope"
  fi
fi

# Save baseline
mkdir -p "$cache_dir"
printf '%s\n' "${results[@]}" > "$cache_file"

# Build category counts
declare -A cat_counts
for line in "${results[@]}"; do
  cat_label="${line%%|*}"
  if [[ -z "${cat_counts[$cat_label]+set}" ]]; then
    cat_counts[$cat_label]=1
  else
    cat_counts[$cat_label]=$((cat_counts[$cat_label] + 1))
  fi
done

# Sorted category list by count descending
cat_order=()
while IFS= read -r line; do
  cat_order+=("$line")
  done < <(for cat in "${!cat_counts[@]}"; do printf '%d\t%s\n' "${cat_counts[$cat]}" "$cat"; done | sort -rn | cut -f2)

if [[ "$findings" -eq 0 ]]; then
  printf '[%s] no installed binaries use nix-ld\n' "$scope"
else
  printf '[%s] === summary ===\n' "$scope"
  for cat in "${cat_order[@]}"; do
    printf '[%s]   %-16s %4d\n' "$scope" "$cat" "${cat_counts[$cat]}"
  done
  printf '[%s]   %-16s %4d\n' "$scope" "total" "$findings"

  printf '\n[%s] === paths ===\n' "$scope"
  for line in "${results[@]}"; do
    cat_label="${line%%|*}"
    path="${line#*|}"
    short="$path"
    [[ -n "$home_real" && "$path" == "$home_real"/* ]] && short="~${path#"$home_real"}"
    printf '[%s]   %s  %s\n' "$scope" "$cat_label" "$short"
  done
fi

if [[ "$runtime_tree_excluded" -gt 0 ]]; then
  printf '[%s] excluded %d binaries inside runtime trees (chroot structure)\n' \
    "$scope" "$runtime_tree_excluded"
fi
if [[ "$ignored_by_user" -gt 0 ]]; then
  printf '[%s] ignored %d binaries by user ignore list (%s)\n' \
    "$scope" "$ignored_by_user" "$ignore_file"
fi
printf '[%s] done: %d binaries use nix-ld, %d categories, %d roots scanned\n' \
  "$scope" "$findings" "${#cat_order[@]}" "${#scan_roots[@]}"

if [[ "$diff_mode" -eq 1 && "$new_findings" -gt 0 ]]; then
  printf '[%s] WARNING: %d new nix-ld users since last scan\n' "$scope" "$new_findings" >&2
  exit 1
fi

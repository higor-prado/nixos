#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF2'
Usage: scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-experience]

Examples:
  scripts/new-host-skeleton.sh zeus desktop dms-on-niri
  scripts/new-host-skeleton.sh ci-runner server
EOF2
}

templates_dir="$REPO_ROOT/templates/new-host-skeleton"

render_template() {
  local template_name="$1" target="$2" content
  content="$(<"${templates_dir}/${template_name}")"
  content="${content//__HOST_NAME__/${host_name}}"
  content="${content//__DESKTOP_FEATURES__/${desktop_features:-}}"
  printf '%s\n' "$content" >"$target"
}

desktop_features_for() {
  case "$1" in
    dms-on-niri)
      cat <<'EOF2'

      desktop-dms-on-niri
      niri
      dms
      dms-wallpaper
      desktop-base
      desktop-apps
      desktop-viewers
      wayland-tools
      xwayland
EOF2
      ;;
    niri-standalone)
      cat <<'EOF2'

      desktop-niri-standalone
      niri
      desktop-base
      desktop-apps
      desktop-viewers
      wayland-tools
      xwayland
EOF2
      ;;
    *)
      log_fail "new-host-skeleton" "unsupported desktop experience: $1"
      exit 1
      ;;
  esac
}

host_name="${1:-}"
host_role="${2:-desktop}"
desktop_experience="${3:-dms-on-niri}"

if [[ "$host_name" == "-h" || "$host_name" == "--help" || "$host_name" == "help" ]]; then
  usage
  exit 0
fi

if [[ -z "$host_name" ]]; then
  usage >&2
  exit 1
fi

if [[ ! "$host_name" =~ ^[a-z0-9-]+$ ]]; then
  log_fail "new-host-skeleton" "host-name must match ^[a-z0-9-]+$"
  exit 1
fi

if [[ "$host_role" != "desktop" && "$host_role" != "server" ]]; then
  log_fail "new-host-skeleton" "role must be 'desktop' or 'server'"
  exit 1
fi

if [[ ! "$desktop_experience" =~ ^[a-z0-9-]+$ ]]; then
  log_fail "new-host-skeleton" "desktop-experience must match ^[a-z0-9-]+$"
  exit 1
fi

host_dir="hardware/${host_name}"
host_file="${host_dir}/default.nix"
host_module_file="modules/hosts/${host_name}.nix"

if [[ -e "$host_dir" || -e "$host_file" || -e "$host_module_file" ]]; then
  log_fail "new-host-skeleton" "host path already exists: ${host_dir}"
  exit 1
fi

mkdir -p "$host_dir" "$(dirname "$host_module_file")"

if [[ "$host_role" == "desktop" ]]; then
  desktop_features="$(desktop_features_for "$desktop_experience")"
  render_template desktop-hardware.nix.tpl "$host_file"
  render_template desktop-module.nix.tpl "$host_module_file"
else
  render_template server-hardware.nix.tpl "$host_file"
  render_template server-module.nix.tpl "$host_module_file"
fi

cat <<EOF2
[new-host-skeleton] created ${host_file}
[new-host-skeleton] created ${host_module_file}

Add this descriptor entry to hardware/host-descriptors.nix:

  ${host_name} = {
    integrations = {
      # toggle host integrations as needed
      # disko = true;
      # homeManager = true;
      # terminal = true;
    };
  };
EOF2

if [[ "$host_role" == "desktop" ]]; then
  cat <<EOF2

Next steps:
  1. If the host should use home-manager, set:
     den.hosts.x86_64-linux.${host_name}.users.<user-aspect>.classes = [ "homeManager" ];
  2. Add home-manager-settings to ${host_module_file} includes.
  3. Adjust the system architecture, feature list, and descriptor integrations.
EOF2
else
  cat <<EOF2

Next steps:
  1. Adjust the system architecture and server feature list in ${host_module_file}.
  2. Add disko/hardware imports in ${host_file} if this stops being an eval-only skeleton.
EOF2
fi

cat <<'EOF2'

Remember to git add new files under modules/ before running nix eval/build;
den's import tree only sees tracked files.
EOF2

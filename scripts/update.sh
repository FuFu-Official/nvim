#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$SCRIPT_DIR/lib/bootstrap.sh"

SYNC_PLUGINS=1
UPDATE_ALL=0
UPDATE_TOOLS=()

usage() {
  cat <<'EOF'
Usage: scripts/update.sh [options]

Update managed release tools and sync Lazy.nvim plugins.

By default this updates only tools already installed under ./bin.
Use --all to update/install every managed tool, or --tool TOOL for a specific one.

Options:
  --dry-run    Print actions without changing files
  --force      Reinstall managed tools even when already current
  --all        Update/install every managed release tool
  --tool TOOL  Update/install one managed release tool
  --no-sync    Skip Lazy.nvim plugin sync
  -h, --help   Show this help
EOF
}

contains_value() {
  local needle="$1"
  shift
  local value
  for value in "$@"; do
    [[ "$value" == "$needle" ]] && return 0
  done
  return 1
}

add_unique_tool() {
  local tool="$1"
  local known

  for known in $(managed_tools); do
    if [[ "$known" == "$tool" ]]; then
      contains_value "$tool" "${UPDATE_TOOLS[@]}" || UPDATE_TOOLS+=("$tool")
      return 0
    fi
  done

  die "unknown managed tool: $tool"
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --all) UPDATE_ALL=1 ;;
    --tool)
      shift
      (($#)) || die "--tool requires a managed tool name"
      add_unique_tool "$1"
      ;;
    --tool=*)
      add_unique_tool "${1#--tool=}"
      ;;
    --no-sync) SYNC_PLUGINS=0 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

"$SCRIPT_DIR/scan-config.sh"

if [[ "$UPDATE_ALL" == "1" ]]; then
  mapfile -t UPDATE_TOOLS < <(managed_tools)
elif ((${#UPDATE_TOOLS[@]} == 0)); then
  mapfile -t UPDATE_TOOLS < <(installed_managed_tools)
fi

if ((${#UPDATE_TOOLS[@]})); then
  install_managed_tools "${UPDATE_TOOLS[@]}"
else
  warn "no managed tools are installed under $BIN_DIR; use --all or --tool TOOL to install one"
fi

if [[ "$SYNC_PLUGINS" == "1" ]]; then
  log "syncing Neovim plugins with Lazy.nvim"
  run_nvim_headless '+Lazy! sync' '+qa'
fi

log "done"

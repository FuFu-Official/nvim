#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$SCRIPT_DIR/lib/bootstrap.sh"

CLEAN_PLUGINS=0

usage() {
  cat <<'EOF'
Usage: scripts/clean.sh [options]

Remove generated bootstrap artifacts from this repository.

Options:
  --dry-run   Print actions without deleting files
  --plugins   Also run Lazy.nvim clean before removing local nvim
  -h, --help  Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --plugins) CLEAN_PLUGINS=1 ;;
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

if [[ "$CLEAN_PLUGINS" == "1" ]]; then
  log "cleaning unused Lazy.nvim plugins"
  run_nvim_headless '+Lazy! clean' '+qa'
fi

log "removing managed bin tools and bootstrap cache"
remove_managed_tools
run rm -rf "$CACHE_DIR"

if [[ -d "$BIN_DIR" ]]; then
  run rmdir "$BIN_DIR" 2>/dev/null || true
fi

log "done"

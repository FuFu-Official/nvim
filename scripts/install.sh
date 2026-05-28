#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$SCRIPT_DIR/lib/bootstrap.sh"

INSTALL_APT=1
INSTALL_MANAGED=1
INSTALL_ALL=0
SYNC_PLUGINS=1
ASSUME_YES=0

APT_UPDATED=0
WITH_GROUPS=()
EXTRA_MANAGED_TOOLS=()

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [options]

Install a Neovim work environment for this config on Ubuntu/Debian.

Default install is intentionally small:
  - apt basics for downloading/searching: curl, git, jq, tar/unzip/xz, ripgrep, fd-find, fzf
  - nvim from the official Neovim release into ./bin
  - Lazy.nvim plugin sync

Optional groups:
  git         lazygit
  ai          opencode
  build       build/source fallback toolchains: build-essential, cmake, ninja, gettext,
              pkg-config, nodejs/npm, cargo, go
  latex       texlive-xetex, zathura

LSP servers, formatters, and linters are intentionally not install groups.
LazyVim/Mason should install editor tools such as pyright, stylua, prettier,
markdownlint-cli2, clang-format, and markdown-oxide.

Options:
  --dry-run             Print actions without changing the system
  --force               Reinstall managed release tools even if current
  --with GROUP[,GROUP]  Install optional group(s)
  --tool TOOL           Install an individual managed release tool
  --all                 Install all optional groups
  --minimal             Install only the default core set
  --list-groups         Show optional groups and exit
  --yes                 Do not prompt after low-space warnings
  --no-apt              Skip apt package installation
  --no-managed          Skip ./bin managed release tools
  --no-sync             Skip Lazy.nvim plugin sync
  -h, --help            Show this help

Examples:
  scripts/install.sh
  scripts/install.sh --with git,ai
  scripts/install.sh --tool lazygit
  scripts/install.sh --all
EOF
}

list_groups() {
  cat <<'EOF'
Optional install groups:
  git         lazygit
  ai          opencode
  build       build/source fallback toolchains
  latex       xelatex and zathura
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

add_unique() {
  local array_name="$1"
  local value="$2"
  local -n array_ref="$array_name"

  contains_value "$value" "${array_ref[@]}" && return 0
  array_ref+=("$value")
}

managed_tool_exists() {
  local tool="$1"
  local known
  for known in $(managed_tools); do
    [[ "$known" == "$tool" ]] && return 0
  done
  return 1
}

enable_group() {
  local group="$1"

  [[ "$group" == "core" ]] && return 0
  [[ "$group" == "lsp" ]] && die "the lsp group was removed; use Mason/LazyVim for LSP servers"
  [[ "$group" == "formatters" ]] && die "the formatters group was removed; use Mason/LazyVim for formatters and linters"
  valid_optional_group "$group" || die "unknown install group: $group"
  add_unique WITH_GROUPS "$group"
}

enable_groups_csv() {
  local csv="$1"
  local group
  local old_ifs="$IFS"

  IFS=','
  for group in $csv; do
    IFS="$old_ifs"
    [[ -n "$group" ]] || continue
    enable_group "$group"
    IFS=','
  done
  IFS="$old_ifs"
}

enable_tool() {
  local tool="$1"

  managed_tool_exists "$tool" || die "unknown managed tool: $tool"
  add_unique EXTRA_MANAGED_TOOLS "$tool"
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --all) INSTALL_ALL=1 ;;
    --minimal)
      INSTALL_ALL=0
      WITH_GROUPS=()
      EXTRA_MANAGED_TOOLS=()
      ;;
    --with)
      shift
      (($#)) || die "--with requires a group name"
      enable_groups_csv "$1"
      ;;
    --with=*)
      enable_groups_csv "${1#--with=}"
      ;;
    --with-git) enable_group git ;;
    --with-ai) enable_group ai ;;
    --with-formatters) die "the formatters group was removed; use Mason/LazyVim for formatters and linters" ;;
    --with-lsp) die "the lsp group was removed; use Mason/LazyVim for LSP servers" ;;
    --with-build) enable_group build ;;
    --with-latex) enable_group latex ;;
    --tool)
      shift
      (($#)) || die "--tool requires a managed tool name"
      enable_tool "$1"
      ;;
    --tool=*)
      enable_tool "${1#--tool=}"
      ;;
    --list-groups)
      list_groups
      exit 0
      ;;
    --yes) ASSUME_YES=1 ;;
    --no-apt) INSTALL_APT=0 ;;
    --no-managed) INSTALL_MANAGED=0 ;;
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

selected_groups() {
  printf '%s\n' core
  if [[ "$INSTALL_ALL" == "1" ]]; then
    optional_groups
  else
    ((${#WITH_GROUPS[@]})) && printf '%s\n' "${WITH_GROUPS[@]}"
  fi
}

selected_optional_count() {
  if [[ "$INSTALL_ALL" == "1" ]]; then
    optional_groups | wc -l
  else
    if ((${#WITH_GROUPS[@]})); then
      printf '%s\n' "${WITH_GROUPS[@]}" | wc -l
    else
      printf '0\n'
    fi
  fi
}

selected_managed_tools() {
  local tools=()
  local group
  local tool

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    while IFS= read -r tool; do
      [[ -n "$tool" ]] || continue
      add_unique tools "$tool"
    done < <(managed_tools_for_group "$group")
  done < <(selected_groups)

  for tool in "${EXTRA_MANAGED_TOOLS[@]}"; do
    add_unique tools "$tool"
  done

  ((${#tools[@]})) && printf '%s\n' "${tools[@]}"
}

apt_packages_for_group() {
  case "$1" in
    core)
      cat <<'EOF'
ca-certificates
curl
git
jq
tar
gzip
unzip
xz-utils
ripgrep
fd-find
fzf
EOF
      ;;
    build)
      cat <<'EOF'
build-essential
cmake
ninja-build
gettext
pkg-config
nodejs
npm
cargo
golang-go
EOF
      ;;
    latex)
      cat <<'EOF'
texlive-xetex
zathura
EOF
      ;;
    git | ai)
      ;;
    *)
      die "unknown install group for apt packages: $1"
      ;;
  esac
}

selected_apt_packages() {
  local packages=()
  local group
  local package

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    while IFS= read -r package; do
      [[ -n "$package" ]] || continue
      add_unique packages "$package"
    done < <(apt_packages_for_group "$group")
  done < <(selected_groups)

  ((${#packages[@]})) && printf '%s\n' "${packages[@]}"
}

join_array() {
  local sep="$1"
  shift
  local first=1
  local item

  for item in "$@"; do
    [[ -n "$item" ]] || continue
    if [[ "$first" == "1" ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$sep" "$item"
    fi
  done
}

estimate_install_mb() {
  local estimate=450
  local group
  local tool

  while IFS= read -r group; do
    case "$group" in
      git) estimate=$((estimate + 100)) ;;
      ai) estimate=$((estimate + 300)) ;;
      build) estimate=$((estimate + 2600)) ;;
      latex) estimate=$((estimate + 4500)) ;;
    esac
  done < <(selected_groups)

  for tool in "${EXTRA_MANAGED_TOOLS[@]}"; do
    case "$tool" in
      nvim) estimate=$((estimate + 250)) ;;
      lazygit) estimate=$((estimate + 80)) ;;
      opencode) estimate=$((estimate + 250)) ;;
    esac
  done

  printf '%s\n' "$estimate"
}

print_selection_summary() {
  local groups
  local tools
  local apt
  local selected_group_array=()

  mapfile -t selected_group_array < <(selected_groups)

  groups="$(join_array ', ' "${selected_group_array[@]}")"
  tools="$(join_array ', ' "${SELECTED_MANAGED_TOOLS[@]}")"
  apt="$(join_array ', ' "${SELECTED_APT_PACKAGES[@]}")"

  log "selected install groups: ${groups:-none}"
  printf 'Managed ./bin tools: %s\n' "${tools:-none}"
  printf 'Apt packages: %s\n' "${apt:-none}"
}

available_disk_min_mb() {
  df -Pm "$ROOT_DIR" "$HOME" / 2>/dev/null | awk 'NR > 1 { if (min == "" || $4 < min) min = $4 } END { print min + 0 }'
}

print_disk_report() {
  log "disk space before install"
  df -h "$ROOT_DIR" "$HOME" / 2>/dev/null | awk 'NR == 1 || !seen[$6]++ { print }'
}

confirm_low_space() {
  local estimate_mb="$1"
  local available_mb="$2"
  local optional_count="$3"
  local large_selection=0

  if [[ "$INSTALL_ALL" == "1" || "$optional_count" -ge 4 || "$estimate_mb" -ge 3000 ]]; then
    large_selection=1
  fi

  print_disk_report
  log "estimated selected install footprint: about ${estimate_mb} MB"

  if [[ "$available_mb" -le 0 ]]; then
    warn "could not determine available disk space"
    return 0
  fi

  if [[ "$available_mb" -lt 1024 || ( "$large_selection" == "1" && "$available_mb" -lt $((estimate_mb + 1024)) ) ]]; then
    cat >&2 <<EOF

**********************************************************************
WARNING: LOW DISK SPACE FOR THE SELECTED INSTALL

Smallest free filesystem checked: ${available_mb} MB
Estimated selected install footprint: about ${estimate_mb} MB
Selected optional groups: ${optional_count}

You selected all or a large part of the environment while free space is
limited. Heavy groups such as build and latex can pull
large apt/npm/cargo dependency trees.
**********************************************************************

EOF

    if [[ "$DRY_RUN" == "1" || "$ASSUME_YES" == "1" ]]; then
      return 0
    fi

    if [[ -t 0 ]]; then
      read -r -p "Continue anyway? [y/N] " answer
      [[ "$answer" == "y" || "$answer" == "Y" ]] || die "aborted because of low disk space"
    else
      warn "non-interactive shell; continuing after low-space warning"
    fi
  fi
}

install_apt_packages() {
  local requested=("$@")
  local available=()
  local missing=()
  local package

  ((${#requested[@]})) || return 0

  if [[ "$INSTALL_APT" != "1" ]]; then
    warn "apt package installation is disabled; skipping: ${requested[*]}"
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "1" ]]; then
      warn "apt-get is not available here; showing Ubuntu/Debian apt actions for dry-run"
    else
      die "this installer expects Ubuntu/Debian with apt-get"
    fi
  fi

  if [[ "$APT_UPDATED" == "0" ]]; then
    log "updating apt package metadata"
    run_sudo apt-get update
    APT_UPDATED=1
  fi

  for package in "${requested[@]}"; do
    [[ -n "$package" ]] || continue
    if [[ "$DRY_RUN" == "1" ]] || apt-cache show "$package" >/dev/null 2>&1; then
      available+=("$package")
    else
      missing+=("$package")
    fi
  done

  if ((${#missing[@]})); then
    warn "apt package(s) unavailable in this distro release: ${missing[*]}"
  fi

  if ((${#available[@]})); then
    log "installing apt packages"
    run_sudo apt-get install -y "${available[@]}"
  fi
}

ensure_fd_command() {
  if command -v fd >/dev/null 2>&1; then
    return 0
  fi

  if command -v fdfind >/dev/null 2>&1; then
    log "linking fdfind as fd under ~/.local/bin"
    run mkdir -p "$HOME/.local/bin"
    run ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
}

build_prereq_packages() {
  case "$1" in
    nvim)
      printf '%s\n' build-essential cmake ninja-build gettext pkg-config
      ;;
    lazygit)
      printf '%s\n' golang-go
      ;;
    opencode)
      printf '%s\n' nodejs npm
      ;;
  esac
}

install_build_prereqs() {
  local tool="$1"
  local packages=()
  local package

  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    packages+=("$package")
  done < <(build_prereq_packages "$tool")

  ((${#packages[@]})) || return 0
  warn "official release asset fallback for $tool needs build/package prerequisites: ${packages[*]}"
  install_apt_packages "${packages[@]}"
}

mapfile -t SELECTED_APT_PACKAGES < <(selected_apt_packages)
mapfile -t SELECTED_MANAGED_TOOLS < <(selected_managed_tools)

"$SCRIPT_DIR/scan-config.sh"
print_selection_summary
confirm_low_space "$(estimate_install_mb)" "$(available_disk_min_mb)" "$(selected_optional_count)"

install_apt_packages "${SELECTED_APT_PACKAGES[@]}"
ensure_fd_command
ensure_dirs

if [[ "$INSTALL_MANAGED" == "1" ]]; then
  install_managed_tools "${SELECTED_MANAGED_TOOLS[@]}"
else
  warn "managed release tools are disabled; skipping: ${SELECTED_MANAGED_TOOLS[*]:-none}"
fi

if [[ "$SYNC_PLUGINS" == "1" ]]; then
  log "syncing Neovim plugins with Lazy.nvim"
  run_nvim_headless '+Lazy! sync' '+qa'
fi

log "done"
if [[ "$INSTALL_LINKS" == "1" ]]; then
  printf 'Managed tools are stored under: %s\n' "$TOOL_HOME"
  printf 'Command links are installed under: %s\n' "$LINK_DIR"
  printf 'Make sure this directory is in PATH: %s\n' "$LINK_DIR"
else
  printf 'Managed tools are linked under: %s\n' "$BIN_DIR"
fi

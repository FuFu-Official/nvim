#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="${BIN_DIR:-$ROOT_DIR/bin}"
TOOL_HOME="$BIN_DIR/.tools"
CACHE_DIR="${CACHE_DIR:-$ROOT_DIR/.cache/bootstrap}"
BUILD_DIR="$CACHE_DIR/build"
RELEASE_CACHE_DIR="$CACHE_DIR/releases"

DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

need_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    warn "missing command in this environment, continuing dry-run: $1"
    return 0
  fi

  die "missing command: $1"
}

run_sudo() {
  if [[ "$DRY_RUN" == "1" ]]; then
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
      run "$@"
    else
      run sudo "$@"
    fi
    return 0
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    need_cmd sudo
    sudo "$@"
  fi
}

ensure_dirs() {
  run mkdir -p "$BIN_DIR" "$TOOL_HOME" "$CACHE_DIR" "$BUILD_DIR" "$RELEASE_CACHE_DIR"
}

host_arch() {
  case "$(uname -m)" in
    x86_64 | amd64)
      printf 'x86_64'
      ;;
    aarch64 | arm64)
      printf 'aarch64'
      ;;
    *)
      die "unsupported architecture: $(uname -m)"
      ;;
  esac
}

managed_tools() {
  printf '%s\n' nvim lazygit opencode
}

legacy_managed_tools() {
  printf '%s\n' stylua dprint markdown-oxide
}

optional_groups() {
  printf '%s\n' git ai build latex
}

valid_optional_group() {
  case "$1" in
    git | ai | build | latex)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

managed_tools_for_group() {
  case "$1" in
    core) printf '%s\n' nvim ;;
    git) printf '%s\n' lazygit ;;
    ai) printf '%s\n' opencode ;;
    build | latex) ;;
    *) die "unknown install group: $1" ;;
  esac
}

tool_command() {
  case "$1" in
    nvim) printf 'nvim' ;;
    lazygit) printf 'lazygit' ;;
    opencode) printf 'opencode' ;;
    *) die "unknown managed tool: $1" ;;
  esac
}

tool_repo() {
  case "$1" in
    nvim) printf 'neovim/neovim' ;;
    lazygit) printf 'jesseduffield/lazygit' ;;
    opencode) printf 'sst/opencode' ;;
    *) die "unknown managed tool: $1" ;;
  esac
}

asset_regex() {
  local tool="$1"
  local arch
  arch="$(host_arch)"

  case "$tool:$arch" in
    nvim:x86_64) printf '^nvim-linux-x86_64\.tar\.gz$' ;;
    nvim:aarch64) printf '^nvim-linux-arm64\.tar\.gz$' ;;
    lazygit:x86_64) printf '^lazygit_[0-9.]+_linux_x86_64\.tar\.gz$' ;;
    lazygit:aarch64) printf '^lazygit_[0-9.]+_linux_arm64\.tar\.gz$' ;;
    opencode:x86_64) printf '^opencode-linux-x64\.tar\.gz$' ;;
    opencode:aarch64) printf '^opencode-linux-arm64\.tar\.gz$' ;;
    *) die "no release asset pattern for $tool on $arch" ;;
  esac
}

build_supported() {
  case "$1" in
    nvim | lazygit | opencode)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

safe_tag() {
  printf '%s' "$1" | tr '/ :' '---'
}

version_number() {
  printf '%s' "$1" | sed 's/^v//'
}

github_release_json() {
  local repo="$1"
  local cache="$RELEASE_CACHE_DIR/${repo//\//__}.json"

  ensure_dirs
  need_cmd curl
  need_cmd jq

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s' "$cache"
    return 0
  fi

  curl -fsSL \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/$repo/releases/latest" \
    -o "$cache"
  printf '%s' "$cache"
}

latest_release_tag() {
  local json="$1"
  jq -r '.tag_name // empty' "$json"
}

release_asset_url() {
  local json="$1"
  local regex="$2"
  jq -r --arg regex "$regex" '
    .assets[]
    | select(.name | test($regex))
    | .browser_download_url
  ' "$json" | head -n 1
}

installed_tag() {
  local tool="$1"
  local file="$TOOL_HOME/$tool/current.version"
  [[ -f "$file" ]] && cat "$file"
}

download_file() {
  local url="$1"
  local output="$2"
  need_cmd curl
  run curl -fL --retry 3 --retry-delay 2 "$url" -o "$output"
}

extract_archive() {
  local archive="$1"
  local output_dir="$2"

  case "$archive" in
    *.tar.gz | *.tgz)
      need_cmd tar
      run tar -xzf "$archive" -C "$output_dir"
      ;;
    *.zip)
      need_cmd unzip
      run unzip -q "$archive" -d "$output_dir"
      ;;
    *)
      die "unsupported archive format: $archive"
      ;;
  esac
}

link_tool_binary() {
  local tool="$1"
  local command_name
  local binary_path="$2"
  local version="$3"

  command_name="$(tool_command "$tool")"
  run chmod +x "$binary_path"
  run ln -sfn "$binary_path" "$BIN_DIR/$command_name"
  if [[ "$DRY_RUN" != "1" ]]; then
    mkdir -p "$TOOL_HOME/$tool"
    printf '%s\n' "$version" >"$TOOL_HOME/$tool/current.version"
  fi
}

install_release_asset() {
  local tool="$1"
  local tag="$2"
  local url="$3"
  local command_name
  local safe
  local destination
  local staging
  local archive
  local binary_path

  command_name="$(tool_command "$tool")"
  safe="$(safe_tag "$tag")"
  destination="$TOOL_HOME/$tool/$safe"
  staging="$CACHE_DIR/staging-$tool-$safe"
  archive="$CACHE_DIR/${tool}-${safe}-${url##*/}"

  log "installing $tool $tag from official release"
  run rm -rf "$staging" "$destination"
  run mkdir -p "$staging" "$destination"
  download_file "$url" "$archive"
  extract_archive "$archive" "$staging"
  run cp -a "$staging/." "$destination/"

  if [[ "$DRY_RUN" == "1" ]]; then
    run ln -sfn "$destination/<extracted>/$command_name" "$BIN_DIR/$command_name"
    return 0
  fi

  binary_path="$(find "$destination" -type f -name "$command_name" -print -quit)"
  [[ -n "$binary_path" ]] || die "could not find $command_name in $url"
  link_tool_binary "$tool" "$binary_path" "$tag"
}

build_from_source() {
  local tool="$1"
  local tag="$2"

  build_supported "$tool" || die "no official binary was found for $tool, and no source build fallback is defined"

  case "$tool" in
    nvim) build_nvim "$tag" ;;
    lazygit) build_lazygit "$tag" ;;
    opencode) build_npm_tool "$tool" opencode-ai "$tag" ;;
    *) die "unreachable build target: $tool" ;;
  esac
}

build_npm_tool() {
  local tool="$1"
  local package="$2"
  local tag="$3"
  local version
  local safe
  local prefix
  local command_name

  version="$(version_number "$tag")"
  safe="$(safe_tag "$tag")"
  prefix="$TOOL_HOME/$tool/$safe"
  command_name="$(tool_command "$tool")"

  log "installing $tool $tag from npm package $package"
  if declare -F install_build_prereqs >/dev/null 2>&1; then
    install_build_prereqs "$tool"
  fi
  need_cmd npm
  run rm -rf "$prefix"
  run mkdir -p "$prefix"
  run npm install -g --prefix "$prefix" "$package@$version"
  [[ "$DRY_RUN" == "1" ]] || link_tool_binary "$tool" "$prefix/bin/$command_name" "$tag"
}

build_nvim() {
  local tag="$1"
  local safe
  local source_dir
  local prefix

  safe="$(safe_tag "$tag")"
  source_dir="$BUILD_DIR/neovim-$safe"
  prefix="$TOOL_HOME/nvim/$safe"

  log "building nvim $tag from source"
  if declare -F install_build_prereqs >/dev/null 2>&1; then
    install_build_prereqs nvim
  fi
  need_cmd git
  need_cmd make
  need_cmd cmake

  run rm -rf "$source_dir" "$prefix"
  run git clone --depth 1 --branch "$tag" https://github.com/neovim/neovim.git "$source_dir"
  run make -C "$source_dir" CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$prefix" install

  [[ "$DRY_RUN" == "1" ]] || link_tool_binary nvim "$prefix/bin/nvim" "$tag"
}

build_lazygit() {
  local tag="$1"
  local safe
  local prefix

  safe="$(safe_tag "$tag")"
  prefix="$TOOL_HOME/lazygit/$safe"

  log "building lazygit $tag from source"
  if declare -F install_build_prereqs >/dev/null 2>&1; then
    install_build_prereqs lazygit
  fi
  need_cmd go
  run rm -rf "$prefix"
  run mkdir -p "$prefix/bin"
  if [[ "$DRY_RUN" == "1" ]]; then
    run env "GOBIN=$prefix/bin" go install "github.com/jesseduffield/lazygit@$tag"
  else
    GOBIN="$prefix/bin" go install "github.com/jesseduffield/lazygit@$tag"
    link_tool_binary lazygit "$prefix/bin/lazygit" "$tag"
  fi
}

build_cargo_tool() {
  local tool="$1"
  local crate="$2"
  local tag="$3"
  local version
  local safe
  local prefix
  local command_name

  version="$(version_number "$tag")"
  safe="$(safe_tag "$tag")"
  prefix="$TOOL_HOME/$tool/$safe"
  command_name="$(tool_command "$tool")"

  log "building $tool $tag from source"
  if declare -F install_build_prereqs >/dev/null 2>&1; then
    install_build_prereqs "$tool"
  fi
  need_cmd cargo
  run rm -rf "$prefix"
  run cargo install "$crate" --version "$version" --locked --root "$prefix"
  [[ "$DRY_RUN" == "1" ]] || link_tool_binary "$tool" "$prefix/bin/$command_name" "$tag"
}

install_managed_tool() {
  local tool="$1"
  local repo
  local json
  local tag
  local current
  local regex
  local url
  local command_name

  repo="$(tool_repo "$tool")"
  command_name="$(tool_command "$tool")"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "would resolve latest $tool release from $repo (source/package fallback is available)"
    return 0
  fi

  json="$(github_release_json "$repo")"
  tag="$(latest_release_tag "$json")"
  [[ -n "$tag" && "$tag" != "null" ]] || die "could not resolve latest release tag for $repo"

  current="$(installed_tag "$tool" || true)"
  if [[ "$FORCE" != "1" && "$current" == "$tag" && -x "$BIN_DIR/$command_name" ]]; then
    log "$tool is already at $tag"
    return 0
  fi

  regex="$(asset_regex "$tool")"
  url="$(release_asset_url "$json" "$regex")"
  if [[ -n "$url" && "$url" != "null" ]]; then
    install_release_asset "$tool" "$tag" "$url"
  else
    warn "no matching official release asset for $tool $tag using /$regex/"
    build_from_source "$tool" "$tag"
  fi
}

install_managed_tools() {
  local tool
  local tools=("$@")

  if ((${#tools[@]} == 0)); then
    mapfile -t tools < <(managed_tools)
  fi

  ensure_dirs
  for tool in "${tools[@]}"; do
    install_managed_tool "$tool"
  done
}

installed_managed_tools() {
  local tool
  local command_name

  for tool in $(managed_tools); do
    command_name="$(tool_command "$tool")"
    if [[ -f "$TOOL_HOME/$tool/current.version" || -x "$BIN_DIR/$command_name" ]]; then
      printf '%s\n' "$tool"
    fi
  done
}

remove_managed_tools() {
  local tool
  local command_name

  for tool in $(managed_tools); do
    command_name="$(tool_command "$tool")"
    run rm -f "$BIN_DIR/$command_name"
  done
  for tool in $(legacy_managed_tools); do
    run rm -f "$BIN_DIR/$tool"
    run rm -rf "$TOOL_HOME/$tool"
  done
  run rm -rf "$TOOL_HOME"
}

repo_config_env() {
  printf 'XDG_CONFIG_HOME=%s' "$(dirname "$ROOT_DIR")"
}

run_nvim_headless() {
  local nvim_bin="$BIN_DIR/nvim"

  if [[ ! -x "$nvim_bin" ]]; then
    nvim_bin="$(command -v nvim || true)"
  fi

  if [[ -z "$nvim_bin" ]]; then
    warn "nvim is not installed; skipping Neovim headless command"
    return 0
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    run env "$(repo_config_env)" "$nvim_bin" --headless "$@"
  else
    XDG_CONFIG_HOME="$(dirname "$ROOT_DIR")" "$nvim_bin" --headless "$@"
  fi
}

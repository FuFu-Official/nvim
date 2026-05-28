#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

has_text() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -q -- "$pattern" "$@" 2>/dev/null
  else
    grep -R -E -q -- "$pattern" "$@" 2>/dev/null
  fi
}

MANAGED=()
PACKAGE_MANAGER=()
MASON_TOOLS=()
OPTIONAL=()
NOTES=()

if [[ -f "$ROOT_DIR/init.lua" ]]; then
  MANAGED+=("nvim|editor runtime: apt is usually too old on Ubuntu/Debian")
fi

if has_text 'lazyvim\.plugins\.extras\.lang\.git' "$ROOT_DIR/lazyvim.json"; then
  MANAGED+=("lazygit|LazyVim git extra")
fi

if has_text 'opencode --port|require\("opencode"\)' "$ROOT_DIR/lua" "$ROOT_DIR/lazy-lock.json"; then
  MANAGED+=("opencode|opencode.nvim starts the opencode CLI")
fi

if has_text '"stylua"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("stylua|Lua formatter")
fi

if has_text '"dprint"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("dprint|Formatter for markdown/json/toml/typescript/dockerfile")
fi

MASON=()

if has_text '"isort"|"black"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("black/isort|Python formatters")
fi

if has_text '"prettier"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("prettier|JavaScript/CSS/Markdown formatter")
fi

if has_text '"clang-format"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("clang-format|C/C++ formatter")
fi

if has_text '"rustfmt"|lazyvim\.plugins\.extras\.lang\.rust' "$ROOT_DIR/lua" "$ROOT_DIR/lazyvim.json"; then
  MASON_TOOLS+=("rustfmt|Rust formatter; usually installed with rustup/toolchain")
fi

if has_text 'lua_ls' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("lua-language-server|Lua LSP")
fi

if has_text 'clangd' "$ROOT_DIR/lua/plugins/lsp.lua" "$ROOT_DIR/lazyvim.json"; then
  MASON+=("clangd|C/C++ LSP")
fi

if has_text 'pyright' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("pyright|Python LSP")
fi

if has_text 'fish_lsp' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("fish-lsp|Fish shell LSP")
fi

if has_text 'cmake = \{\}' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("cmake-language-server|CMake LSP")
fi

if has_text 'hyprls' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("hyprls|Hyprland LSP; install from upstream if Mason cannot")
fi

if has_text 'bashls' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("bash-language-server|Bash LSP")
fi

if has_text 'jsonls' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("vscode-json-language-server|JSON LSP")
fi

if has_text 'texlab' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("texlab|LaTeX LSP")
fi

if has_text 'markdown_oxide' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  MASON+=("markdown-oxide|Markdown LSP")
fi

if has_text 'markdownlint-cli2' "$ROOT_DIR/lua/plugins/lint.lua"; then
  MASON_TOOLS+=("markdownlint-cli2|Markdown linter")
fi

if has_text '"fmtron"' "$ROOT_DIR/lua/plugins/conform.lua"; then
  MASON_TOOLS+=("fmtron|RON formatter")
fi

if [[ -f "$ROOT_DIR/lsp/ron_lsp.lua" ]]; then
  NOTES+=("ron-lsp config file exists, but the server is commented out in lua/plugins/lsp.lua")
fi

if has_text 'xelatex|zathura' "$ROOT_DIR/lua/plugins/lsp.lua"; then
  OPTIONAL+=("texlive-xetex/zathura|required only for LaTeX build and forward search")
fi

if has_text 'kitty-scrollback' "$ROOT_DIR/lua/plugins/kitty.lua" "$ROOT_DIR/lazy-lock.json"; then
  OPTIONAL+=("kitty|needed only for kitty-scrollback integration")
fi

printf 'Config scan: %s\n' "$ROOT_DIR"
printf '\nDetected managed tools that can be installed into bin/:\n'
for item in "${MANAGED[@]}"; do
  printf '  - %-16s %s\n' "${item%%|*}" "${item#*|}"
done

if ((${#PACKAGE_MANAGER[@]})); then
  printf '\nDetected optional non-LSP command-line dependencies:\n'
  for item in "${PACKAGE_MANAGER[@]}"; do
    printf '  - %-28s %s\n' "${item%%|*}" "${item#*|}"
  done
fi

if ((${#MASON[@]})); then
  printf '\nDetected LSP servers; configure/install these with Mason/LazyVim:\n'
  for item in "${MASON[@]}"; do
    printf '  - %-28s %s\n' "${item%%|*}" "${item#*|}"
  done
fi

if ((${#MASON_TOOLS[@]})); then
  printf '\nDetected formatters/linters; configure/install these with Mason/LazyVim or the language toolchain:\n'
  for item in "${MASON_TOOLS[@]}"; do
    printf '  - %-28s %s\n' "${item%%|*}" "${item#*|}"
  done
fi

if ((${#OPTIONAL[@]})); then
  printf '\nOptional/heavy desktop dependencies:\n'
  for item in "${OPTIONAL[@]}"; do
    printf '  - %-24s %s\n' "${item%%|*}" "${item#*|}"
  done
fi

if ((${#NOTES[@]})); then
  printf '\nNotes:\n'
  for item in "${NOTES[@]}"; do
    printf '  - %s\n' "$item"
  done
fi

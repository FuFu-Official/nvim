# Neovim Bootstrap

Scripts in `scripts/` bootstrap this LazyVim config on Ubuntu/Debian.

The installer scans the local config before doing work, but it does not install every detected dependency by default.

- Default install is intentionally small: apt basics for downloading/searching and Treesitter parser builds, plus `nvim` and `tree-sitter` from official GitHub releases.
- `lazygit` and `opencode` can be installed from upstream release binaries when their groups are selected.
- LSP servers, formatters, and linters are left to LazyVim/Mason. The bootstrap scan reports them, but the shell installer does not install them.
- Non-editor system tools are opt-in through apt when needed.
- Before installing, the script prints disk space and warns loudly if free space is low for a large selection.

Managed release binaries are stored inside this repository under `bin/.tools/`.
The script also creates command links in `~/.local/bin` by default:

```text
~/.local/bin/nvim -> /path/to/this/repo/bin/.tools/nvim/<version>/...
```

That means the downloaded files stay owned by this repo's scripts, while normal shell commands can find `nvim`, `lazygit`, or `opencode` through `~/.local/bin`.

The script does not edit your shell rc file. If `~/.local/bin` is not already in `PATH`, add this to `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

To link commands somewhere else, set `LINK_DIR`:

```sh
LINK_DIR="$HOME/bin" scripts/install.sh
```

To keep links only inside this repository and not write into `~/.local/bin`:

```sh
INSTALL_LINKS=0 scripts/install.sh
```

## Scripts

```sh
scripts/scan-config.sh
scripts/install.sh
scripts/update.sh
scripts/clean.sh
```

`scripts/install.sh` installs the minimal core set, then runs Lazy.nvim sync.

Useful options:

```sh
scripts/install.sh --dry-run
scripts/install.sh --with git,ai
scripts/install.sh --tool lazygit
scripts/install.sh --all
scripts/install.sh --no-sync
```

Optional install groups:

- `git`: `lazygit`
- `ai`: `opencode`
- `build`: build/source fallback toolchains
- `latex`: `texlive-xetex`, `zathura`

Use `scripts/install.sh --list-groups` to print this from the script.

`scripts/update.sh` updates already-installed upstream release tools and syncs Lazy.nvim:

```sh
scripts/update.sh
scripts/update.sh --force
scripts/update.sh --tool lazygit
scripts/update.sh --all
scripts/update.sh --no-sync
```

`scripts/clean.sh` removes generated release tools and bootstrap cache:

```sh
scripts/clean.sh
scripts/clean.sh --plugins
```

`--plugins` runs Lazy.nvim clean before removing the local `nvim` binary.

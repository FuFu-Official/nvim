# Neovim Bootstrap

Scripts in `scripts/` bootstrap this LazyVim config on Ubuntu/Debian.

The installer scans the local config before doing work, but it does not install every detected dependency by default.

- Default install is intentionally small: apt basics for downloading/searching plus `nvim` from the official Neovim GitHub release.
- `lazygit` and `opencode` can be installed from upstream release binaries when their groups are selected.
- LSP servers, formatters, and linters are left to LazyVim/Mason. The bootstrap scan reports them, but the shell installer does not install them.
- Non-editor system tools are opt-in through apt when needed.
- Before installing, the script prints disk space and warns loudly if free space is low for a large selection.

Managed release binaries are linked into `bin/` in this repository. Add it before system paths:

```sh
export PATH="$HOME/.config/nvim/bin:$HOME/.local/bin:$PATH"
```

If you clone this repo somewhere other than `~/.config/nvim`, use that clone path instead.

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

`scripts/update.sh` updates already-installed upstream release tools in `bin/` and syncs Lazy.nvim:

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

return {
  -- {
  --   "ellisonleao/gruvbox.nvim",
  --   opts = {
  --     transparent_mode = true,
  --   },
  -- },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  {
    "catppuccin/nvim",
    opts = {
      flavour = "mocha",
      transparent_background = false,
      auto_integrations = true,
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "moon",
      styles = {
        transparency = true,
      },
    },
  },
  {
    "RRethy/base16-nvim",
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
  {
    "eandrju/cellular-automaton.nvim",
  },
  {
    "Aasim-A/scrollEOF.nvim",
    event = { "CursorMoved", "WinScrolled" },
    opts = {
      insert_mode = true,
      floating = false,
      disabled_filetypes = { "NvimTree", "lazy", "terminal", "snacks_terminal" },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        signature = {
          auto_open = { enabled = false },
        },
      },
    },
  },
  {
    "xiyaowong/transparent.nvim",
    opts = {
      extra_groups = {
        "NormalFloat",
        "FloatBorder",
      },
    },
    config = function(_, opts)
      require("transparent").setup(opts)
      require("transparent").clear_prefix("gitsigns")
    end,
  },
}

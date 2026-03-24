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
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.remove(opts.sections.lualine_c, 1)
      table.remove(opts.sections.lualine_c, #opts.sections.lualine_c)
      table.insert(opts.sections.lualine_c, {
        "filename",
        path = 3,
      })
      opts.options.theme = "base16"
    end,
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

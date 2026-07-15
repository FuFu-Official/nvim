return {
  {
    "nvim-mini/mini.pairs",
    enabled = false,
  },
  {
    "nvim-mini/mini.ai",
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = opts.mappings or {}
      opts.mappings.around_next = "ae"
      opts.mappings.around_last = "ie"

      return opts
    end,
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
  -- {
  --   "folke/noice.nvim",
  --   opts = {
  --     lsp = {
  --       signature = {
  --         auto_open = { enabled = false },
  --       },
  --     },
  --   },
  -- },
}

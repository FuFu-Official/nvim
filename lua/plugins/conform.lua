return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "isort", "black" },
      javascript = { "prettier" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      dockerfile = { "dprint" },
      json = { "dprint" },
      jsonc = { "dprint" },
      toml = { "dprint" },
      typescript = { "dprint" },
      css = { "prettier" },
      ron = { "fmtron" },
    },
  },
}

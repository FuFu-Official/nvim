return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { "prettier", "prettier", stop_after_first = true },
      c = { "clang-format" },
      cpp = { "clang-format" },
      markdown = { "dprint", "prettier", stop_after_first = true },
      dockerfile = { "dprint" },
      json = { "dprint" },
      jsonc = { "dprint" },
      toml = { "dprint" },
      typescript = { "dprint" },
      css = { "prettier" },
      rust = { "rustfmt" },
      ron = { "fmtron" },
    },
  },
}

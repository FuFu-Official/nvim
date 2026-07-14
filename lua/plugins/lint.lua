local HOME = os.getenv("HOME")
return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      -- Fix markdown lint isssue
      ["markdownlint-cli2"] = {
        args = { "--config", HOME .. "/.config/nvim/dots/.markdownlint-cli2.yaml", "--" },
      },
    },
  },
}

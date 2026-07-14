return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      servers = {
        pyright = {},
        fish_lsp = {},
        cmake = {},
        hyprls = {},
        bashls = {},
        texlab = {
          settings = {
            texlab = {
              build = {
                executable = "xelatex",
                args = { "-interaction=nonstopmode", "-synctex=1", "%f" },
                forwardSearchAfter = true,
                onSave = true,
              },
              forwardSearch = {
                args = { "--synctex-forward", "%l:1:%f", "%p" },
                executable = "zathura",
              },
            },
          },
        },
        jsonls = {
          settings = {
            json = {
              schemas = {
                { fileMatch = { "*.json", "*.jsonc" }, schema = { allowTrailingCommas = true } },
              },
            },
          },
        },
      },
    },
  },
}

-- LazyVim default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Change the default root directory
vim.g.root_spec = { "lsp", "cwd", { ".git", "lua" } }

-- Enable OSC 52 clipboard support for SSH connections
if vim.env.SSH_CONNECTION then
  vim.opt.clipboard = "unnamedplus"

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

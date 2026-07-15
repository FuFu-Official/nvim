-- LazyVim default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local keymap = vim.keymap

keymap.set("n", "1", "^", { desc = "Move to first non-blank character of the line" })
keymap.set("n", "0", "$", { desc = "Move to the end of the line" })

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode using 'jk'" })

keymap.set("v", "q", "<Esc>", { silent = true, desc = "Exit visual mode" })

keymap.set("n", "U", "<C-r>", { desc = "Redo last undone change" })

keymap.set("n", "J", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! J")
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Join line without cursor jump" })

keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without yanking" })

keymap.set("n", "x", '"_x', { desc = "Delete character without copying" })

keymap.set("n", "+", "<C-a>", { desc = "Increment number under cursor" })
keymap.set("n", "-", "<C-x>", { desc = "Decrement number under cursor" })

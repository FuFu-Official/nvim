-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

-- Exit insert mode quickly by pressing "jk"
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode using 'jk'" })

-- Exit visual mode using "q"
keymap.set("v", "q", "<Esc>", { silent = true, desc = "Exit visual mode" })

-- U for redo
keymap.set("n", "U", "<C-r>", { desc = "Redo last undone change" })

-- Move selected lines up/down
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

-- Join lines without moving the cursor
-- keymap.set("n", "J", "mzJ`z", { desc = "Join line without cursor jump" })
keymap.set("n", "J", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd("normal! J")
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Join line without cursor jump" }) -- cleaner than the previous version

---When pasting a selection, keep the text
keymap.set("x", "p", [["_dP]])

-- Delete a character without affecting default registers
keymap.set("n", "x", '"_x', { desc = "Delete character without copying" })

-- Increment/decrement numbers under the cursor
keymap.set("n", "+", "<C-a>", { desc = "Increment number under cursor" })
keymap.set("n", "-", "<C-x>", { desc = "Decrement number under cursor" })

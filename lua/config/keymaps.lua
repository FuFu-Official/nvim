-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap

-- Exit insert mode quickly by pressing "jk"
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode using 'jk'" })

-- Exit visual mode using "q"
keymap.set("v", "q", "<Esc>", { silent = true, desc = "Exit visual mode" })

-- Move selected lines up/down
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

-- Join lines without moving the cursor
keymap.set("n", "J", "mzJ`z", { desc = "Join line without cursor jump" })

---When pasting a selection, keep the text
keymap.set("x", "p", [["_dP]])

-- Delete a character without affecting default registers
keymap.set("n", "x", '"_x', { desc = "Delete character without copying" })

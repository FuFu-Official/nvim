-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
vim.api.nvim_create_user_command("VimChroot", function(opts)
  local path = opts.args

  if path == "" then
    path = vim.fn.expand("%:p:h")
  end

  if vim.fn.isdirectory(path) == 1 then
    vim.api.nvim_set_current_dir(path)
    vim.g.root_spec = { "cwd" }

    vim.notify("🚀 Root switch to: " .. path, vim.log.levels.INFO)
  else
    vim.notify("❌ ERROR: Not a valid directory -> " .. path, vim.log.levels.ERROR)
  end
end, {
  nargs = "?",
  complete = "dir",
  desc = "chroot to a specified path",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "ron",
  callback = function()
    vim.bo.commentstring = "// %s"
  end,
})

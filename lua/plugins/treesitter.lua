return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- add tsx and treesitter
    vim.list_extend(opts.ensure_installed, {
      "bash",
      "fish",
      "c",
      "cpp",
      "diff",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "vim",
      "vimdoc",
      "query",
      "regex",
      "css",
      "html",
      "javascript",
      "latex",
      "scss",
      "svelte",
      "typst",
      "vue",
      "astro",
      "json",
    })
  end,
}

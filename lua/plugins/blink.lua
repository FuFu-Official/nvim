return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      preset = "default",
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      -- ["<Tab>"] = { "select_next", "fallback" },
      ["<C-h>"] = {
        function(cmp)
          cmp.scroll_documentation_down(4)
        end,
      },
      ["<C-l>"] = {
        function(cmp)
          cmp.scroll_documentation_up(4)
        end,
      },
    },
  },
}

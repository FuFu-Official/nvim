return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "default",
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
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

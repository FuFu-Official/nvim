return {
  "folke/snacks.nvim",
  opts = {
    image = {
      doc = {
        inline = false,
        float = false,
      },
    },
  },
  keys = {
    {
      "<leader>um",
      function()
        Snacks.image.hover()
      end,
      desc = "Image Hover",
    },
  },
}

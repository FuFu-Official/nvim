return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    set({ "n", "x" }, "<leader>mn", function()
      mc.matchAddCursor(1)
    end, { desc = "Match Add Cursor" })
    set({ "n", "x" }, "<leader>ms", function()
      mc.matchSkipCursor(1)
    end, { desc = "Match Skip Cursor" })
    set({ "n", "x" }, "<leader>mN", function()
      mc.matchAddCursor(-1)
    end, { desc = "Match Add prevCursor" })
    set({ "n", "x" }, "<leader>mS", function()
      mc.matchSkipCursor(-1)
    end, { desc = "Match Skip prevCursor" })

    set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "Toggle Cursor" })

    mc.addKeymapLayer(function(layerSet)
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)
      layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}

return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {},
          picker = {
            actions = {
              opencode_send = function(...)
                return require("opencode").snacks_picker_send(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("opencode").toggle()
        end,
        mode = { "n", "t" },
        desc = "Toggle opencode",
      },
      {
        "<leader>as",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        mode = { "n", "x" },
        desc = "Ask opencode",
      },
      {
        "<leader>ax",
        function()
          require("opencode").select()
        end,
        mode = { "n", "x" },
        desc = "Select opencode action",
      },
      {
        "<leader>ao",
        function()
          return require("opencode").operator("@this ")
        end,
        mode = { "n", "x" },
        expr = true,
        desc = "Add range to opencode",
      },
      {
        "<leader>aO",
        function()
          return require("opencode").operator("@this ") .. "_"
        end,
        mode = "n",
        expr = true,
        desc = "Add line to opencode",
      },
      {
        "<leader>ak",
        function()
          require("opencode").command("session.page.up")
        end,
        mode = "n",
        desc = "Scroll opencode up",
      },
      {
        "<leader>aj",
        function()
          require("opencode").command("session.page.down")
        end,
        mode = "n",
        desc = "Scroll opencode down",
      },
    },
    config = function()
      local opencode_cmd = "opencode --port"
      local snacks_terminal_opts = {
        interactive = false,
        win = {
          position = "right",
          width = 0.4,
          enter = false,
          on_win = function(win)
            require("opencode.terminal").setup(win.win)
          end,
        },
      }

      local has_snacks, snacks_terminal = pcall(require, "snacks.terminal")
      vim.g.opencode_opts = {
        lsp = { enabled = true },
        server = {
          start = function()
            if has_snacks then
              snacks_terminal.open(opencode_cmd, snacks_terminal_opts)
            else
              vim.notify("snacks.nvim is not available", vim.log.levels.WARN)
            end
          end,
          stop = function()
            if has_snacks then
              local terminal = snacks_terminal.get(
                opencode_cmd,
                vim.tbl_deep_extend("force", {
                  create = false,
                }, snacks_terminal_opts)
              )
              if terminal then
                local job_id = terminal.buf and vim.b[terminal.buf] and vim.b[terminal.buf].terminal_job_id
                if job_id then
                  pcall(vim.fn.jobstop, job_id)
                end
                terminal:close()
              end
            end
          end,
          toggle = function()
            if has_snacks then
              snacks_terminal.toggle(opencode_cmd, snacks_terminal_opts)
            else
              vim.notify("snacks.nvim is not available", vim.log.levels.WARN)
            end
          end,
        },
      }

      vim.o.autoread = true
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_z = opts.sections.lualine_z or {}
      local statusline = function()
        local ok, opencode = pcall(require, "opencode")
        if ok and opencode.statusline then
          return opencode.statusline()
        end
        return ""
      end

      for _, component in ipairs(opts.sections.lualine_z) do
        if component == statusline then
          return
        end
      end

      table.insert(opts.sections.lualine_z, 1, statusline)
    end,
  },
}

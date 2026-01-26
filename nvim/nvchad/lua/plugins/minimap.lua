return {
  "echasnovski/mini.map",
  version = "*",
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    { "<leader>um", function() require("mini.map").toggle() end, desc = "Toggle minimap" },
  },
  opts = function()
    local map = require "mini.map"
    return {
      integrations = {
        map.gen_integration.builtin_search(),
        map.gen_integration.gitsigns(),
        map.gen_integration.diagnostic {
          error = "DiagnosticFloatingError",
          warn = "DiagnosticFloatingWarn",
          info = "DiagnosticFloatingInfo",
          hint = "DiagnosticFloatingHint",
        },
      },
      symbols = {
        encode = map.gen_encode_symbols.dot "3x2",
        -- Scrollbar parts for view and line. Use empty string to disable any.
        scroll_line = '',
        scroll_view = '',
      },
      window = {
        side = "right",
        width = 1,
        winblend = 0,
        show_integration_count = false,
      },
    }
  end,
  config = function(_, opts)
    local map = require "mini.map"
    map.setup(opts)

    local group = vim.api.nvim_create_augroup("MiniMapAutoOpen", { clear = true })

    local function should_open()
      if vim.bo.filetype == "minimap" then
        return false
      end

      local buftype = vim.bo.buftype
      return buftype == "" or buftype == "help"
    end

    local function update()
      if vim.g.minimap_disable == true or vim.b.minimap_disable == true then
        map.close()
        return
      end

      if not should_open() then
        map.close()
        return
      end

      map.open()
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
      group = group,
      callback = update,
      desc = "Auto open minimap",
    })

    vim.schedule(update)
  end,
  specs = {
    {
      "catppuccin",
      optional = true,
      ---@type CatppuccinOptions
      opts = { integrations = { mini = true } },
    },
  },
}

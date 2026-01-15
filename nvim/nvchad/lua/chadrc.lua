-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyodark",
  -- transparency = true,
  theme_toggle = { "tokyodark", "ayu_light" },

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}

M.nvdash = { load_on_startup = true }

M.ui = {
  cmp = {
    icons = true,
    lspkind_text = true,
  },

  tabufline = {
    lazyload = false,
  },

  statusline = {
    -- order is vscode with triforce added
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "triforce", "cursor", "cwd" },
    modules = {
      triforce = function()
        return require("triforce.lualine").level {
          show_bar = true,
          show_percent = true,
        } .. " | " .. require("triforce.lualine").streak() .. " | " .. require("triforce.lualine").session_time() .. " "
      end,
    },
  },

  telescope = { style = "bordered" }, -- borderless / bordered
}

return M

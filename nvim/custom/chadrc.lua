---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "catppuccin",
  transparency = true,

  telescope = { style = "bordered" }, -- borderless / bordered
}

M.mappings = require "custom.mappings"

M.plugins = "custom.plugins"

return M

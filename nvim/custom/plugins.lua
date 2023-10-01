---@type NvPluginSpec[]
local plugins = {

  {
    "nvim-tree/nvim-tree.lua",
    opts = require("custom.configs.nvimtree").nvimtree,
  },

}

return plugins

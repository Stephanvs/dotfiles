---@type NvPluginSpec[]
local plugins = {

  {
    "nvim-tree/nvim-tree.lua",
    opts = require("custom.configs.nvimtree").nvimtree,
  },

  {
    "williamboman/mason.nvim",
    opts = require("custom.configs.mason").mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = require("custom.configs.treesitter").treesitter,
  },

  -- If your opts uses a function call, then make opts spec a function*
  -- should return the modified default config as well
  -- here we just call the default telescope config 
  -- and then assign a function to some of its options
  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      local conf = require "plugins.configs.telescope"
      conf.defaults.mappings.i = {
        ["<C-j>"] = require("telescope.actions").move_selection_next,
        ["<C-k>"] = require("telescope.actions").move_selection_previous,
        ["<Esc>"] = require("telescope.actions").close,
      }
      return conf
    end,
  }

}

return plugins

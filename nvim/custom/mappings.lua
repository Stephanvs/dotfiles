---@type MappingsTable
local M = {}

M.default = {
  n = {
    -- ["<Up>"] = { "<Nop>", "Disabled up arrow" },
    -- ["<Down>"] = { "<Nop>", "Disabled down arrow" },
    -- ["<Left>"] = { "<Nop>", "Disabled left arrow" },
    -- ["<Right>"] = { "<Nop>", "Disabled right arrow" },

    ["<C-n>"] = { "<cmd> Telescope <CR>", "Telescope" },
    ["<C-s>"] = { ":Telescope Files <CR>", "Telescope Files" }
  },

  i = {
    -- ["<Up>"] = { "<Nop>", "Disabled up arrow" },
    -- ["<Down>"] = { "<Nop>", "Disabled down arrow" },
    -- ["<Left>"] = { "<Nop>", "Disabled left arrow" },
    -- ["<Right>"] = { "<Nop>", "Disabled right arrow" },

    [ "jk" ] = { "<ESC>", "escape insert mode", opts = { nowait = true }},
  },

  x = {
    -- ["<Up>"] = { "<Nop>", "Disabled up arrow" },
    -- ["<Down>"] = { "<Nop>", "Disabled down arrow" },
    -- ["<Left>"] = { "<Nop>", "Disabled left arrow" },
    -- ["<Right>"] = { "<Nop>", "Disabled right arrow" }
  }
}

M.nvimtree_mappings = require("custom.configs.nvimtree")

return M

local M = {}

---@type MappingsTable
M.nvimtree_mappings = {
  n = {
    ["<leader>e"] = { "<cmd> NvimTreeToggle <CR>" },
  },
}

M.nvimtree = {
  sort_by = "case_sensitive",

  git = {
    enable = true,
  },

  on_attach = function (bufnr)
    local api = require "nvim-tree.api"

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    local function edit_or_open()
      local node = api.tree.get_node_under_cursor()

      if node.nodes ~= nil then
        -- expand or collapse folder
        api.node.open.edit()
      else
        -- open file
        api.node.open.edit()
        -- Close the tree if file was opened
        -- api.tree.close()
      end
    end

    -- open as vsplit on current node
    local function vsplit_preview()
      local node = api.tree.get_node_under_cursor()

      if node.nodes ~= nil then
        -- expand or collapse folder
        api.node.open.edit()
      else
        -- open file as vsplit
        api.node.open.vertical()
      end

      -- Finally refocus on tree if it was lost
      api.tree.focus()
    end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- custom mappings
    vim.keymap.set('n', 'l', edit_or_open,          opts("Edit or Open"))
    vim.keymap.set("n", "L", vsplit_preview,        opts("Vsplit Preview"))
    vim.keymap.set("n", "h", api.tree.close,        opts("Close"))
    vim.keymap.set("n", "H", api.tree.collapse_all, opts("Collapse All"))
   end,

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M

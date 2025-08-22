return {
  "nvim-tree/nvim-tree.lua",
  opts = function()
    local function open_win_config_func()
      return {
        relative = "editor",
        border = "rounded",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        row = math.floor((vim.o.lines - math.floor(vim.o.lines * 0.8)) / 2),
        col = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.8)) / 2),
      }
    end

    return {
      view = {
        float = {
          enable = true,
          open_win_config = open_win_config_func,
        },
      },
    }
  end,
}
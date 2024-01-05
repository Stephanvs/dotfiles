return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  init = function()
    vim.cmd([[colorscheme catppuccin-mocha]])
  end,
  opts = {
    flavor = "mocha", -- latte, frappe, macchiato, mocha
    background = {
      light = "latte",
      dark = "mocha"
    },
    transparent_background = true,
    show_end_of_buffer = false,
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      telescope = true,
      harpoon = true,
      mason = true,
      treesitter = true,
      which_key = true
    }
  }
}
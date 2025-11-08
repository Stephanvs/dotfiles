return {
  "gisketch/triforce.nvim",
  lazy = false,
  dependencies = {
    "nvzone/volt",
  },
  config = function()
    require("triforce").setup {
      -- Optional: Add your configuration here
      keymap = {
        show_profile = "<leader>tp", -- Open profile with <leader>tp
      },
    }
  end,
}

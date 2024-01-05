return {

  {
    "nvim-lua/plenary.nvim",
    name = "plenary"
  },

  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require('Comment').setup()
    end
  },

  { "github/copilot.vim" }

}

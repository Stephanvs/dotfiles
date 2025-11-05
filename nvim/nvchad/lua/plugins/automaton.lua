return {
  "eandrju/cellular-automaton.nvim",
  lazy = false,
  keys = {
    {
      "<leader>fmt",
      "<cmd>CellularAutomaton randomize_ascii<cr>",
      desc = "Randomize ascii cellular automaton",
    },
    {
      "<leader>fml",
      "<cmd>CellularAutomaton game_of_life<cr>",
      desc = "Game of life",
    },
    -- Add more as needed (see usage below)
  },
}

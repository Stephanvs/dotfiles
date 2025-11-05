return {
  "eandrju/cellular-automaton.nvim",
  lazy = false,
  keys = {
    {
      "<leader>fmt",
      "<cmd>CellularAutomaton make_it_rain<cr>",
      desc = "Randomize ascii cellular automaton",
    },
    {
      "<leader>fml",
      "<cmd>CellularAutomaton game_of_life<cr>",
      desc = "Game of life",
    },
  },
}

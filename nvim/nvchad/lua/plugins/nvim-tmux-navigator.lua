return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Tmux navigate left" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Tmux navigate down" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Tmux navigate up" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Tmux navigate right" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Tmux navigate previous" },
  },
}

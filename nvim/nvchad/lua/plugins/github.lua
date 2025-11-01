return {
  "folke/snacks.nvim",
  opts = {
    gh = {
      -- your gh config here. 
      -- or leave empty for default config
    },
    picker = {
      sources = {
        gh_issue = {
          -- gh issue config
        },
        gh_pr = {
          -- gh pr config
        }
      }
    }
  },
  keys = {
    { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
    { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
    { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
    { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
  }
}

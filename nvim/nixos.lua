local M = { lazy_path = "@pluginDirectory@/lazy.nvim" }

function M.configure(options)
  return vim.tbl_deep_extend("force", options, {
    dev = {
      path = function(plugin)
        return "@pluginDirectory@/" .. plugin.name
      end,
      patterns = { "." },
      fallback = false,
    },
    install = { missing = false },
    checker = { enabled = false },
    rocks = { enabled = false },
    pkg = { enabled = false },
    performance = { rtp = { paths = { "@parserDirectory@" } } },
    lockfile = vim.fn.stdpath("state") .. "/nix-lazy-lock.json",
  })
end

M.plugins = {
  { "mason-org/mason.nvim", enabled = false },
  { "LazyVim/LazyVim", enabled = false },
  { "nvchad/base46", build = false },
  {
    "nvchad/ui",
    priority = 1100,
    config = function()
      require("base46").compile()
      require "nvchad"
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = false,
    opts = function(_, options)
      options.ensure_installed = {}
      options.auto_install = false
    end,
  },
  {
    "seblyng/roslyn.nvim",
    opts = { mason = false },
  },
}

return M

vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

local nix
if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/dotfiles/nix.lua") == 1 then
  nix = require "dotfiles.nix"
end

local lazypath = nix and nix.lazy_path or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if nix then
  assert(vim.uv.fs_stat(lazypath), "lazy.nvim is missing from the Nix plugin package")
elseif not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"
if nix then
  lazy_config = nix.configure(lazy_config)
end

-- load plugins
local plugins = {
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}
if nix then
  vim.list_extend(plugins, nix.plugins)
end
require("lazy").setup(plugins, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "configs.autoread"
require "configs.dashboard"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

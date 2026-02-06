require "nvchad.mappings"

local map = vim.keymap.set
local nomap = vim.keymap.del

local function telescope_grep(search)
  local builtin = require "telescope.builtin"
  builtin.grep_string { search = search }
end

-- Remove default navigation keymaps (replaced by TmuxNavigator)
nomap("n", "<c-h>")
nomap("n", "<c-j>")
nomap("n", "<c-k>")
nomap("n", "<c-l>")

-- Save with Ctrl-s
map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- #########
-- Normal mode
-- #########

-- In visual-line mode, move selection up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Merge line-below but keep cursor in place
map("n", "J", "mzJ`z")

-- Keep cursor in place during half-page (U)p / (D)own
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Keep cursor in middle during search navigation
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Greatest remap ever - keep yanked after paste
map("x", "<leader>p", "\"_dP", { desc = "paste without yanking" })

-- Next greatest remap ever - yank to clipboard
map("n", "<leader>y", "\"+y", { desc = "yank to clipboard" })
map("n", "<leader>Y", "\"+Y", { desc = "yank to clipboard" })
map("v", "<leader>y", "\"+y", { desc = "yank to clipboard" })

-- Window navigation
-- map('n', '<c-h>', ':wincmd h<CR>')
-- map('n', '<c-j>', ':wincmd j<CR>')
-- map('n', '<c-k>', ':wincmd k<CR>')
-- map('n', '<c-l>', ':wincmd l<CR>')

-- j or k cancel insert mode
map("i", "jk", "<ESC>")

-- Toggle word wrap
map("n", "<leader>w", "<cmd>set wrap!<CR>", { desc = "toggle word wrap" })

map("n", "<leader>fws", function()
  telescope_grep(vim.fn.expand "<cword>")
end, { desc = "Find word under cursor" })

map("n", "<leader>fp", function()
  telescope_grep(vim.fn.expand "<cWORD>")
end, { desc = "Find WORD under cursor" })

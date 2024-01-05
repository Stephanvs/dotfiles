vim.g.mapleader = " "

-- In visual-line mode, move selection up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Merge line-below but keep cursor in place
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor in place during half-page (U)p / (D)own
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep cursor in middle during search navigation
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Greatest remap ever - keep yanked after paste
vim.keymap.set("x", "<leader>p", "\"_dP", { desc = "paste without yanking" })

-- Next greatest remap ever - yank to clipboard
vim.keymap.set("n", "<leader>y", "\"+y", { desc = "yank to clipboard" })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = "yank to clipboard" })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "yank to clipboard" })

-- Window navigation
vim.keymap.set('n', '<c-h>', '<c-w>h')
vim.keymap.set('n', '<c-j>', '<c-w>j')
vim.keymap.set('n', '<c-k>', '<c-w>k')
vim.keymap.set('n', '<c-l>', '<c-w>l')

-- Buffer deletion
vim.keymap.set('n', '<leader>x', '<Cmd>bd<CR>')

-- Use Tab and Shift-Tab to navigate buffers
vim.keymap.set('n', '<tab>', '<Cmd>bn<CR>')
vim.keymap.set('n', '<s-tab>', '<Cmd>bp<CR>')

-- Comment in Normal mode and Visual mode
vim.keymap.set('n', '<leader>/', function()
    require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle line comment" })
vim.keymap.set('v', '<leader>/', '<ESC><cmd>lua require(\'Comment.api\').toggle.linewise(vim.fn.visualmode())<CR>', { desc = "Toggle line comment" })

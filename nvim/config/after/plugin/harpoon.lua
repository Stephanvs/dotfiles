local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<c-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<m-h>", ui.nav_prev)
vim.keymap.set("n", "<m-l>", ui.nav_next)

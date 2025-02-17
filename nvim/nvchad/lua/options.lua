require "nvchad.options"

local o = vim.o

o.nu = true
o.relativenumber = true

-- indentation
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true

o.smartindent = true
o.wrap = false

o.swapfile = false
o.backup = false
o.undofile = true

o.scrolloff = 8
o.signcolumn = "auto:4"
-- o.isfname.append("@-@")

o.updatetime = 50

o.cursorcolumn = false
o.cursorline = true
o.cursorlineopt ='both' -- to enable cursorline!

o.listchars = "space:·,tab:->,trail:-,nbsp:+"
o.list = true


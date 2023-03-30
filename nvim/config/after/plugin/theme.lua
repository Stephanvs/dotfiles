require('catppuccin').setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = {
        light = 'latte',
        dark = 'mocha',
    },
    transparent_background = true,
    show_end_of_buffer = false, -- show the '~' characters after end of buffers
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        harpoon = true,
        mason = true,
        treesitter = true,
        which_key = true,
    }
})

vim.cmd.colorscheme('catppuccin-mocha')

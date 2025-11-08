return {
    "tpope/vim-fugitive",
    lazy = false,
    config = function()
        vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = "fugitive git status" })
    end
}

return  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 400
    end,
    opts = {
        -- use defaults
    }
}

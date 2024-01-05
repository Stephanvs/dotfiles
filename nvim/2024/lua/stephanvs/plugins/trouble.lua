return {
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            vim.keymap.set("n", "<leader>tt", function()
                require("trouble").toggle()
            end)

            vim.keymap.set("n", "<leader>tn", function()
                require("trouble").next({
                    skip_groups = true,
                    jump = true,
                })
            end)

            vim.keymap.set("n", "<leader>tp", function()
                require("trouble").previous({
                    skip_groups = true,
                    jump = true,
                })
            end)
        end,
        opts = {
            icons = false,
            -- https://github.com/folke/trouble.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
        },
    }
}

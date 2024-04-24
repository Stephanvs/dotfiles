return {
    {
        "folke/trouble.nvim",

        dependencies = { "nvim-tree/nvim-web-devicons" },

        config = function()
            vim.keymap.set("n", "<leader>tt", function()
                require("trouble").toggle()
            end,
            { desc = "toggle trouble" })

            vim.keymap.set("n", "<leader>tn", function()
                require("trouble").next({
                    skip_groups = true,
                    jump = true,
                })
            end,
            { desc = "next diagnostic" })

            vim.keymap.set("n", "<leader>tp", function()
                require("trouble").previous({
                    skip_groups = true,
                    jump = true,
                })
            end,
            { desc = "previous diagnostic" })

            vim.keymap.set("n", "<leader>j", ":TroubleToggle<cr>",
            { desc = "toggle trouble panel" })
        end,

        opts = {
            icons = false,
            -- https://github.com/folke/trouble.nvim?tab=readme-ov-file#%EF%B8%8F-configuration
        },
    }
}

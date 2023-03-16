require("nvim-tree").setup({
    sort_by = "case_sensitive",
    view = {
        mappings = {
            custom_only = false,
            list = {
                { key = "l", action = "edit", action_cb = edit_or_open },
                { key = "L", action = "vsplit_preview", action_cb = vsplit_preview },
                { key = "h", action = "close_node", action_cb = close_node },
                { key = "H", action = "collapse_all", action_cb = collapse_all },
                { key = "g?", action = "toggle_help", action_cb = toggle_help },
            },
        },
    },
    actions = {
        open_file = {
            quit_on_open = false
        }
    }
})

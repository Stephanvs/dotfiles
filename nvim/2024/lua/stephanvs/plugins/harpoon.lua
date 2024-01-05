return {
    "ThePrimeagen/harpoon",

    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    branch = "harpoon2",

    init = function()
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local harpoon = require('harpoon')
        harpoon:setup({})

        local conf = require("telescope.config").values
        local function toggle_telescope(harpoon_files)
            local file_paths = {}
            for _, item in ipairs(harpoon_files.items) do
                table.insert(file_paths, item.value)
            end

            require("telescope.pickers").new({}, {
                prompt_title = "Harpoon",
                finder = require("telescope.finders").new_table({
                    results = file_paths,
                }),
                previewer = conf.file_previewer({}),
                sorter = conf.generic_sorter({}),
                -- Make telescope select buffer from harpoon list
                attach_mappings = function(_, map)
                    local function list_find(list, func)
                        for i, v in ipairs(list) do
                            if func(v, i, list) then
                                return i, v
                            end
                        end
                    end

                    actions.select_default:replace(function(prompt_bufnr)
                        local curr_picker = action_state.get_current_picker(prompt_bufnr)
                        local curr_entry = action_state.get_selected_entry()
                        if not curr_entry then
                            return
                        end
                        actions.close(prompt_bufnr)

                        local idx, _ = list_find(curr_picker.finder.results, function(v)
                            if curr_entry.value == v.value then
                                return true
                            end
                            return false
                        end)
                        harpoon:list():select(idx)
                    end)
                    -- Delete entries from harpoon list with <C-d>
                    map({ 'n', 'i' }, '<C-d>', function(prompt_bufnr)
                        local current_picker = action_state.get_current_picker(prompt_bufnr)

                        current_picker:delete_selection(function(selection)
                            harpoon:list():removeAt(selection.index)
                        end)
                    end
                    )
                    return true
                end
            }):find()
        end

        vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end, { desc = "Add file to harpoon list" })
        vim.keymap.set("n", "<leader>ph", function() toggle_telescope(harpoon:list()) end,
            { desc = "Open harpoon window" })

        vim.keymap.set("n", "<m-h>", function() harpoon:list():prev() end, { desc = "Previous harpoon list entry" })
        vim.keymap.set("n", "<m-l>", function() harpoon:list():next() end, { desc = "Next harpoon list entry" })
    end
}

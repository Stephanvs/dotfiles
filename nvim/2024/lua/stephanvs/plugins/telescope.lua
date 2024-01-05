return {
  "nvim-telescope/telescope.nvim",

  tag = "0.1.5",

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    require("telescope").setup({})
    local builtin = require("telescope.builtin")

    vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Find all files' })
    vim.keymap.set('n', '<leader>pg', builtin.git_files, { desc = 'Find git files' })
    vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = 'Find buffers' })

    vim.keymap.set('n', '<leader>pws', function()
        local word = vim.fn.expand("<cword>")
        builtin.grep_string({ search = word })
    end,
    { desc = 'Find word under cursor' })

    vim.keymap.set('n', '<leader>pWs', function()
        local word = vim.fn.expand("<cWORD>")
        builtin.grep_string({ search = word })
    end,
    { desc = 'Find WORD under cursor' })

    vim.keymap.set('n', '<leader>ps', function()
      builtin.grep_string({ search = vim.fn.input("grep> ") })
    end,
    { desc = 'Find string' })

  end
}

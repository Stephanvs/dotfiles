local builtin = require('telescope.builtin')

-- Go to declaration
-- vim.keymap.set(
--     'n',
--     '<leader>fD',
--     vim.lsp.buf.declaration,
--     { description = 'Go to declaration' })
--
-- -- Go to definition
-- vim.keymap.set(
--     'n',
--     '<leader>fd',
--     builtin.lsp_definitions,
--     { description = 'Go to definition' })

-- Find in files
--vim.keymap.set('n', '<leader>ff', builtin.find_files, { description = 'Find all files' })
--vim.keymap.set('n', '<leader>fg', builtin.git_files, { description = 'Find git files' })
--vim.keymap.set('n', '<leader>fs', function() builtin.grep_string({ search = vim.fn.input("grep> ") }) end, { description = 'Find grep string' })

--vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, { description = 'Show hover' })
--vim.keymap.set('n', '<leader>fi', function() vim.lsp.buf.implementation() end, { description = 'LSP Go to implementation' })
--vim.keymap.set('n', '<leader>fs', function() vim.lsp.buf.signature_help() end, { description = 'LSP Signature help' })

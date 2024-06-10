return {
    {
      'mhartington/formatter.nvim',
      config = function()
        local formatter = { require('formatter.defaults.biome') }
        require("formatter").setup({
          filetype = {
            javascript      = formatter,
            javascriptreact = formatter,
            typescript      = formatter,
            typescriptreact = formatter,
          }
        })
        -- automatically format buffer before writing to disk:
        vim.api.nvim_create_augroup('BufWritePreFormatter', {})
        vim.api.nvim_create_autocmd('BufWritePre', {
          command = 'FormatWrite',
          group = 'BufWritePreFormatter',
          pattern = { '*.js', '*.jsx', '*.ts', '*.tsx' },
        })
      end,
      ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    },
}

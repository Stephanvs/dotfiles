return {
  "austincrft/dotnet-test.nvim",
  dependencies = {
    "skywind3000/asyncrun.vim", -- Required, unless you implement your own build runner
    "mfussenegger/nvim-dap", -- Optional, required for debugging
    "seblyng/roslyn.nvim", -- Optional, required for running all tests in sln
  },
  config = function()
    local dotnet_test = require("dotnet-test")

    -- This plugin does not require calling setup if you're using defaults.
    -- I find the `dotnet build` cmd verbose, so I set it to quiet
    dotnet_test.setup({
      build = {
        args = { "--verbosity", "quiet" },
      },
    })

    -- Creates buffer-scoped mappings for running tests
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "cs",
      callback = function()
        vim.keymap.set("n", "<Leader>tt", function()
          dotnet_test.run_test()
        end, {
          noremap = true,
          silent = true,
          buffer = true,
          desc = "Run .NET test"
        })

        vim.keymap.set("n", "<Leader>td", function()
          dotnet_test.run_test({ debug = true })
        end, {
          noremap = true,
          silent = true,
          buffer = true,
          desc = "Debug .NET test"
        })

        vim.keymap.set("n", "<Leader>tf", function()
          dotnet_test.run_current_file()
        end, {
          noremap = true,
          silent = true,
          buffer = true,
          desc = "Debug .NET tests in file"
        })

        vim.keymap.set("n", "<Leader>ts", function()
          dotnet_test.run_target()
        end, {
          noremap = true,
          silent = true,
          buffer = true,
          desc = "Run .NET tests in sln or proj"
        })
      end,
    })
  end,
}

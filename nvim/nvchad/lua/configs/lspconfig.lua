-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

-- servers with default config
local servers = { "html", "cssls", "csharp_ls", "ts_ls", "rust_analyzer" }

-- enable all servers (capabilities and on_init are set globally by nvchad defaults)
for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

-- to customize a specific server, use vim.lsp.config:
-- vim.lsp.config("ts_ls", {
--   settings = { ... }
-- })

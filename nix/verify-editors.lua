local function check()
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory, "p")
  vim.fn.writefile({ '{"private":true}' }, directory .. "/package.json")
  vim.fn.writefile({ '{"compilerOptions":{"strict":true}}' }, directory .. "/tsconfig.json")
  vim.fn.writefile({ 'const value: number = "incorrect";', "console.log(value);" }, directory .. "/check.ts")
  vim.cmd.edit(directory .. "/check.ts")
  local buffer = vim.api.nvim_get_current_buf()
  local diagnosed = vim.wait(30000, function()
    for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
      if tonumber(diagnostic.code) == 2322 then
        return true
      end
    end
    return false
  end, 100)
  assert(diagnosed, "TypeScript language server did not report the deliberate type mismatch")

  local samples = {
    { "lua", "local value = 1" },
    { "typescript", "const value: number = 1;" },
    { "rust", "fn main() {}" },
    { "c_sharp", "class Example {}" },
  }
  for _, sample in ipairs(samples) do
    local sample_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(sample_buffer, 0, -1, false, { sample[2] })
    local parser = vim.treesitter.get_parser(sample_buffer, sample[1])
    assert(parser, "Parser unavailable: " .. sample[1])
    local trees = parser:parse()
    assert(#trees > 0 and not trees[1]:root():has_error(), "Parser failed: " .. sample[1])
    vim.api.nvim_buf_delete(sample_buffer, { force = true })
  end

  vim.fn.writefile({ "local value={1,2}" }, directory .. "/format.lua")
  vim.cmd.edit(directory .. "/format.lua")
  require("conform").format({ async = false, timeout_ms = 10000, lsp_format = "never" })
  local formatted = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(formatted[1] == "local value = { 1, 2 }", "Lua formatter did not format the buffer")
  print("PASS: NvChad startup, TypeScript diagnostics, Lua/Rust/TypeScript/C# parsing and Lua formatting.")
end

local passed, failure = xpcall(check, debug.traceback)
if vim.env.NIXOS_EDITOR_REPORT then
  local report = (passed and "PASS: editor behavior checks" or failure) .. "\n" .. vim.api.nvim_exec2("messages", { output = true }).output
  vim.fn.writefile(vim.split(report, "\n"), vim.env.NIXOS_EDITOR_REPORT)
end
if not passed then
  io.stderr:write(failure .. "\n")
  vim.cmd.cquit(1)
else
  vim.cmd "qa!"
end

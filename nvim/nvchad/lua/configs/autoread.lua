-- Auto reload files when they change on disk
vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "CursorHoldI", "FocusGained"}, {
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
})
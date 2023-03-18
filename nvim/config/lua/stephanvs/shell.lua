-- Configure powershell on windows and zsh on linux
if vim.fn.has('win32') then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -Command"
  vim.opt.shellquote = "\\"
else
  vim.opt.shell = 'zsh'
end

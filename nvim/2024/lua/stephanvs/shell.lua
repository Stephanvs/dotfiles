-- Configure powershell on windows and zsh on linux
if (vim.fn.has('win32') == 1)
then
    local pwsh_options = {
        shell = vim.fn.executable("pwsh") and "pwsh" or "powershell",
        shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
        shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
        shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
        shellquote = "",
        shellxquote = "",
    }

    for option, value in pairs(pwsh_options) do
        vim.opt[option] = value
    end
else
    vim.opt.shell = 'zsh'
end

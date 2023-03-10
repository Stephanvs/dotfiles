require("tokyonight").setup({
    style = "night",
    transparent = true,
    styles = {
        comments = { italic = true },
        keywords = { italic = true },
    }
})

-- Function to reset colorscheme
function ColorMyPencils(color)
	vim.cmd[[colorscheme tokyonight]]

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMyPencils()


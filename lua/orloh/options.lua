vim.g.netrw_banner = 0

-- Tab and Indent configuration
vim.opt.tabstop = 4
vim.opt.softtabstop = 0
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.scrolloff = 8

vim.opt.wrap = true
vim.opt.smartindent = true
vim.opt.inccommand = "split"

-- Numbers on the side config
vim.opt.number = true
vim.opt.relativenumber = true

-- How window splitting occurs
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.laststatus = 3

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fs.joinpath(vim.fn.stdpath("data"), "undodir")
vim.opt.undofile = true

vim.opt.completeopt = "menuone,noselect,fuzzy,nosort"
vim.opt.shortmess:append("c")

vim.opt.clipboard:append("unnamedplus")
vim.opt.isfname:append("@-@")

vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true

-- Force real tabs in every buffer: filetype plugins (e.g. python) re-enable
-- expandtab, so re-assert the preference after they run.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("orloh-tabs", { clear = true }),
    desc = "Force tabs over spaces in every buffer",
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.softtabstop = 0
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("orloh-yank-highlight", { clear = true }),
    desc = "Highlight when yanking (copying) text",
    callback = function()
        vim.hl.on_yank()
    end
})

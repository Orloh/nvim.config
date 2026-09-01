local status_ok, treesitter = pcall(require, "nvim-treesitter")
if not status_ok then
    vim.notify("nvim-treesitter is not installed yet!", vim.log.levels.WARN)
    return
end

local ensure_installed = {
    "c",
    "python",
    "bash",
    "markdown",
    "markdown_inline",
    "json",
    "yaml",
    "toml",
    "lua",
    "vim",
    "query",
    "sql"
}

treesitter.install(ensure_installed)

-- vim.treesitter.start() resolves the parser from 'filetype' and enables
-- highlighting; pcall guards filetypes without an installed parser.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("orloh-treesitter-start", { clear = true }),
    pattern = "*",
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})

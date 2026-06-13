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
    "json",
    "yaml",
    "toml",
    "lua",
    "vim",
    "query",
    "sql"
}

treesitter.install(ensure_installed)

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function(args)
        local buf = args.buf
        local ft = vim.bo[buf].filetype

        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
            return
        end

        local ok_add = pcall(vim.treesitter.language.add, lang)
        if not ok_add then
            return
        end

        pcall(vim.treesitter.start, buf, lang)
    end,
})

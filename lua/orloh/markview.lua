local status_ok, markview = pcall(require, "markview")
if not status_ok then
    vim.notify("markview is not installed yet!", vim.log.levels.WARN)
    return
end

markview.setup({
    preview = {
        -- Render while reading (normal, operator-pending, command modes)
        modes = { "n", "no", "c" },
        -- Hybrid: the syntax node under the cursor shows raw source while
        -- the rest of the buffer stays rendered
        hybrid_modes = { "n" },
    },
})

-- markview renders tables / block quotes cleanest unwrapped
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("orloh-markview-nowrap", { clear = true }),
    pattern = { "markdown" },
    callback = function()
        vim.opt_local.wrap = false
    end,
})

vim.keymap.set("n", "<leader>m", "<cmd>Markview toggle<cr>", { desc = "Toggle markdown preview" })

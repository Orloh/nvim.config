local status_ok, MiniPick = pcall(require, "mini.pick")
if not status_ok then
    vim.notify("mini.pick is nota installed yet!", vim.log.levels.WARN)
    return
end

MiniPick.setup({
    window = {
        config = {
            border = "rounded",
        },
   },
})

vim.keymap.set("n", "<leader>pf", function()
    MiniPick.builtin.files()
end, { desc = "Project files" })

vim.keymap.set("n", "<C-p>", function()
    MiniPick.builtin.files({ tool = 'git' })
end, { desc = "Git files" })

vim.keymap.set("n", "<leader>ps", function()
    MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Project search (grep word/ search word)" })

vim.keymap.set("n", "<leader>vh", function ()
    MiniPick.builtin.help()
end, { desc = "Mini help" })


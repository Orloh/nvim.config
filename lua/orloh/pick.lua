local mini_ok, MiniPick = pcall(require, "mini.pick")
if not mini_ok then
    vim.notify("mini.pick is nota installed yet!", vim.log.levels.WARN)
    return
end

local extra_ok, MiniExtra = pcall(require, "mini.extra")
if not extra_ok then
    vim.notify("mini.extra is nota installed yet!", vim.log.levels.WARN)
    return
end

MiniPick.setup({
    window = {
        config = {
            border = "rounded",
        },
   },
})

MiniExtra.setup()

-- keymaps
vim.keymap.set("n", "<leader>pf", function()
    MiniPick.builtin.files()
end, { desc = "Project files" })

vim.keymap.set("n", "<leader>ps", function()
    MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Project search (grep word/ search word)" })

vim.keymap.set("n", "<C-p>", function()
    MiniPick.builtin.files({ tool = 'git' })
end, { desc = "Git files" })


vim.keymap.set("n", "<leader>vh", function ()
    MiniPick.builtin.help()
end, { desc = "Mini help" })

vim.keymap.set("n", "<leader>xx", function ()
    MiniExtra.pickers.diagnostics()
end, { desc = "Mini Picker Diagnostics" })

vim.keymap.set("n", "<leader>pk", function ()
    MiniExtra.pickers.keymaps()
end, { desc = "Search keymaps" })

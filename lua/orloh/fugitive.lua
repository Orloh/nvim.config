local MiniDiff = require("mini.diff")
MiniDiff.setup({
    source = MiniDiff.gen_source.git({ index = false }),
})

vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git fugitive" })
vim.keymap.set("n", "<leader>gd", vim.cmd.Gvdiffsplit, { desc = "Git diff split" })

local status_ok, arrow = pcall(require, "arrow")

if not status_ok then
    vim.notify("Arrow is not installed yet!", vim.log.levels.WARN)
    return
end

arrow.setup({
    show_icons = true,
    always_show_path = false,
    leader_key = "<C-e>",
})

local persist = require("arrow.persist")

vim.keymap.set("n", "<leader>a", persist.toggle, { desc = "Arrow Toggle File" })


vim.keymap.set("n", "<C-j>", function() persist.go_to(1) end, { desc = "Arrow File 1" })
vim.keymap.set("n", "<C-k>", function() persist.go_to(2) end, { desc = "Arrow File 2" })
vim.keymap.set("n", "<C-l>", function() persist.go_to(3) end, { desc = "Arrow File 3" })
vim.keymap.set("n", "<C-ñ>", function() persist.go_to(4) end, { desc = "Arrow File 4" })

vim.keymap.set("n", "]a", persist.next, { desc = "Arrow Next File" })
vim.keymap.set("n", "[a", persist.previous, { desc = "Arrow Prev File" })


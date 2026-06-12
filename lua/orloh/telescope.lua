local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
    return
end

local builtin_ok, builtin = pcall(require, "telescope.builtin")
if not builtin_ok then
    return
end

telescope.setup({
    defaults = {
        prompt_prefix = ">",
        selection_caret = "> ",
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
    },
})

telescope.load_extension("fzf")

vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Project files" })
vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>ps", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Project search (grep_string with prompt)" })

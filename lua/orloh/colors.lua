local status_ok, rose_pine = pcall(require, "rose-pine")

if not status_ok then
    vim.notify("rose-pine failed to load!\nError: " .. result, vim.log.levels.WARN)
    return
end

rose_pine.setup()
vim.cmd("colorscheme rose-pine")

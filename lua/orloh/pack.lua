-- 1. Create a dictionary of plugins and their build commands
local build_hooks = {
    ['telescope-fzf-native.nvim'] = { 'make' },
    -- Example: ['markdown-preview.nvim'] = { 'npm', 'install' },
    -- Example: ['telescope-frecency.nvim'] = { 'cargo', 'build', '--release' }
}

-- 2. The Generalized Autocommand
-- vim.api.nvim_create_autocmd('PackChanged', {
--     desc = 'Run custom build steps for plugins after install/update',
--     callback = function(ev)
--         local name = ev.data.spec.name
--         local kind = ev.data.kind
--         local path = ev.data.path
--
--         -- Only run on install or update
--         if kind == 'install' or kind == 'update' then
--
--             -- Look up the plugin name in our build_hooks table
--             local cmd = build_hooks[name]
--
--             -- If a build command exists for this plugin, execute it
--             if cmd then
--                 vim.schedule(function() 
--                     vim.notify("Building " .. name .. "...", vim.log.levels.INFO) 
--                 end)
--
--                 -- Run the command asynchronously so it doesn't freeze Neovim
--                 vim.system(cmd, { cwd = path }, function(out)
--                     if out.code == 0 then
--                         vim.schedule(function() 
--                             vim.notify("Successfully built: " .. name, vim.log.levels.INFO) 
--                         end)
--                     else
--                         vim.schedule(function() 
--                             vim.notify("Failed to build: " .. name .. "\n" .. (out.stderr or ""), vim.log.levels.ERROR) 
--                         end)
--                     end
--                 end)
--             end
--
--         end
--     end,
-- })

-- 3. Your plugins
vim.pack.add({
    {
        src = "https://github.com/rose-pine/neovim",
        name = "rose-pine",
    },
    --'https://github.com/nvim-lua/plenary.nvim',
    --'https://github.com/nvim-telescope/telescope.nvim',
    --'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
})




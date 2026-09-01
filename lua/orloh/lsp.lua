require("mason").setup()

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format local buffer" })
vim.keymap.set("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("mini.completion").get_lsp_capabilities())

vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            hint = { enable = true },
        }
    }
})

vim.lsp.config("pyright", {
    settings = {
        pyright = {
            -- ruff owns organize-imports
            disableOrganizeImports = true,
        },
    },
})

vim.lsp.config("ruff", {})
vim.lsp.config("bashls", {})

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
    },
})

vim.lsp.enable({
    "lua_ls",
    "pyright",
    "ruff",
    "bashls",
    "clangd",
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("orloh-lsp-attach", { clear = true }),
    desc = "Enable inlay hints when the attached server supports them",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method("textDocument/inlayHint", args.buf) then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
        end
    end,
})

vim.keymap.set("n", "<leader>ch", function()
    if vim.fn.exists(":LspClangdSwitchSourceHeader") == 2 then
        vim.cmd.LspClangdSwitchSourceHeader()
    else
        vim.notify("clangd is not attached to this buffer", vim.log.levels.WARN)
    end
end, { desc = "Switch between C source and header" })

local MiniSnippets = require("mini.snippets")
MiniSnippets.setup()

local MiniCompletion = require("mini.completion")

MiniCompletion.setup({
    lsp_completion = {
        auto_setup = true,
    },
})

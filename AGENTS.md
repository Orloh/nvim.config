# AGENTS.md

Personal Neovim config (module namespace `lua/orloh/`). Runs on Neovim 0.12.x and
deliberately uses new-era APIs — legacy patterns common in training data are wrong here.

## Hard API constraints

- Plugins: built-in `vim.pack` only (`lua/orloh/pack.lua`). No lazy.nvim/packer. The
  lockfile `nvim-pack-lock.json` is committed — after changing plugins run `:PackUpdate`
  and commit the lockfile.
- LSP: use `vim.lsp.config("<server>", {...})` + `vim.lsp.enable()`. Never
  `require("lspconfig").<server>.setup()`. nvim-lspconfig is installed only to supply
  default `lsp/*.lua` server configs (e.g. clangd's buffer-local
  `:LspClangdSwitchSourceHeader`).
- Exact API surface of this binary (0.12.2): `vim.lsp.get_client_by_id()` is correct
  (`vim.lsp.client()` as a function is 0.13-only); inlay hints are
  `vim.lsp.inlay_hint.enable(bool, { bufnr = ... })`, not the 0.13 `vim.lsp.inlay`.
  Verify new API calls headless before committing them.
- Treesitter: pinned `branch = "main"` (the rewrite). Configure via
  `require("nvim-treesitter").install({...})` plus a FileType autocmd calling
  `vim.treesitter.start()` (see `treesitter.lua`). The legacy `ensure_installed`/`setup()`
  API does not exist on this branch, and the plugin does not auto-start parsers.
- `init.lua` line 1 (`require("vim._core.ui2").enable({})`) must stay before
  `require("orloh")`; it is a private/experimental API — do not restructure.

## Structure

- `init.lua` → `lua/orloh/init.lua` requires one module per concern in a fixed order:
  options → remap → commands → pack → colors → notify → pick → arrow → fugitive →
  treesitter → markview → completions → lsp. `pack.lua` must precede modules that
  `require` plugins; `remap.lua` sets `vim.g.mapleader` (`<Space>`) before plugin
  keymaps. A new module = new file under `lua/orloh/` + a require in that list.
- Plugin keymaps live in the module that owns the plugin (not remap.lua), always with
  `desc`. Diagnostics maps use the `<leader>x*` prefix. Before adding keymaps, audit
  existing ones with `<leader>pk` (mini.extra keymap picker) — they are spread across
  modules.
- First-run-optional plugins load behind `pcall(require, ...)` + `vim.notify`
  (colors, treesitter, pick, arrow); mini.* modules assume mini.nvim from pack.lua.
  Autocmds are grouped via `vim.api.nvim_create_augroup("orloh-*", { clear = true })`.

## Commands & verification

- `:PackAdd url...`, `:PackDel name...`, `:PackUpdate [name...]` wrap `vim.pack`.
- Mason installs LSP servers manually (`:Mason` / `:MasonInstall <name>`); there is no
  mason-lspconfig bridge. Servers resolve from Mason's bin dir at runtime, not PATH.
- Apply config changes with `<leader>re` / `:restart` rather than re-sourcing files.
- No tests/lint/CI. Verify edits with `nvim --headless '+qa'` (must exit 0 silently) and
  `:checkhealth` for LSP/treesitter. For an LSP smoke test, open a C/Python file
  headless and wait for `vim.lsp.get_clients({ bufnr = 0 })` to populate.

## Workflow facts

- Primary languages C and Python. Servers: clangd (formatting, inlay hints,
  header/source switch via `<leader>ch`), pyright (types only — it has NO formatting
  and NO inlayHint capability, verified against 1.1.410; Pylance/basedpyright carry
  those), ruff (Python lint + format), lua_ls (inlay hints on), bashls.
- `<leader>f` (`vim.lsp.buf.format`) formats via whichever attached server formats.
- Markdown renders in-buffer via markview.nvim (hybrid mode; `<leader>m` toggles
  per-buffer; markdown buffers force `wrap=false`). It needs the `markdown` +
  `markdown_inline` treesitter parsers and must not be lazy-loaded. Its `state` API
  takes real buffer numbers only — it never resolves `0` to the current buffer.
- Dependency philosophy: prefer mini.nvim modules and builtins (mini.pick, mini.snippets,
  builtin `nvim.undotree` via `<leader>u`, `vim.snippet`) over adding new plugins; keep
  `pack.lua` minimal. See `docs/critique.md` for the full review this setup is based on.

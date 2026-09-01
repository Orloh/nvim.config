# Neovim Configuration Critique

Reviewed against the running system on 2026-09-01: **Neovim 0.12.2** (Release, LuaJIT),
plugin revisions per `nvim-pack-lock.json`, pyright 1.1.410, ruff 0.16.5, clangd 22.1.6.
Every claim below was verified either by reading the installed plugin/runtime source or
by executing a headless check (see Appendix A).

Structure of this document:

- [Priority summary](#priority-summary) — all findings, most critical first
- [1. Lua Best Practices & Modernization](#1-lua-best-practices--modernization)
- [2. LSP & Autocompletion Optimization](#2-lsp--autocompletion-optimization)
- [3. Performance & Startup Time](#3-performance--startup-time)
- [4. Keybindings & Workflow](#4-keybindings--workflow)
- [5. Optional next steps (not applied)](#5-optional-next-steps-not-applied)
- [Appendix A — verification log](#appendix-a--verification-log)

---

## Priority summary

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| 1 | **Critical** | clangd (your primary server) was not installed anywhere — C files had zero LSP | **Fixed** — installed 22.1.6 via Mason |
| 2 | **Critical** | `<leader>f` was a no-op in Python: pyright has no formatting capability | **Fixed** — ruff server enabled |
| 3 | High | No inlay hints despite clangd supporting them | **Fixed** — LspAttach autocmd |
| 4 | High | No keybinding for clangd header/source switch (core C workflow) | **Fixed** — `<leader>ch` |
| 5 | Medium | `<leader>d` / `<leader>df` prefix collision causes `timeoutlen` stall on every "delete without yanking" | **Fixed** — diagnostics moved to `<leader>xd` |
| 6 | Medium | `alwasy_show_path` typo silently disabling the arrow.nvim option | **Fixed** |
| 7 | Medium | `<C-S-P>` / `<C-S-N>` arrow maps unreachable — terminals cannot distinguish shifted Ctrl-chars | **Fixed** — `]a` / `[a` |
| 8 | Low | Debug `print("hello")` on every startup (also bypasses mini.notify) | **Fixed** |
| 9 | Low | LSP snippets inserted as raw text: mini.snippets never set up | **Fixed** |
| 10 | Low | Dead code & style: commented-out `diagnostic.config`, mixed tabs in `commands.lua`, invalid `colorcolumn = "0"`, typos | **Fixed** |
| 11 | Low | pyright lacks inlay hints (Pylance-only feature) — swap to basedpyright if wanted | Optional |
| 12 | Low | No debugging setup (DAP) for C or Python | Optional |

What was already good and left alone: the module architecture (flat, one concern per
file, explicit load order — not monolithic, not fragmented), the `vim.lsp.config` /
`vim.lsp.enable` modern LSP API, `vim.pack` with a committed lockfile, no global
variable leaks, completion capabilities merge, and the `<leader>x*` diagnostics
namespace convention.

---

## 1. Lua Best Practices & Modernization

### 1.1 No global leaks, idiomatic core (verdict: keep)

All modules use locals correctly; no `glob = ...` leaks found. The codebase already
avoids every deprecated API class relevant to 0.12:

- `vim.keymap.set` (not `vim.api.nvim_set_keymap` with raw `noremap` option tables)
- `vim.opt.*` (not `vim.o` / `set` strings)
- `vim.hl.on_yank()` (the 0.11+ rename of `vim.highlight.on_yank`)
- `vim.cmd.packadd("nvim.undotree")` — builtin undotree, a 0.12 feature most configs
  still use a plugin for. Good.

### 1.2 Version-sensitive API traps (the real modernization risk)

The single biggest "modernization" risk in this config is not old code — it is
**future** API drift, because it deliberately rides new-era APIs. Verified on this
exact binary:

```lua
-- 0.12.2 (this binary) — CORRECT:
local client = vim.lsp.get_client_by_id(args.data.client_id)
vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })

-- 0.13 (nightly renames) — WRONG on 0.12.2, will error at runtime:
local client = vim.lsp.client(args.data.client_id)  -- 'attempt to call field "client" (a table value)'
vim.lsp.inlay.enable(args.buf, true)                -- vim.lsp.inlay is nil on 0.12.2
```

Both wrong forms were live in an earlier draft of this session and caught only by the
headless smoke test — which is exactly why `nvim --headless '+qa'` verification is now
codified in `AGENTS.md`. When you upgrade to 0.13, invert this advice.

### 1.3 Structure: right-sized, keep as-is

`init.lua` → 12 flat modules under `lua/orloh/` with a fixed require order. This is the
correct size for a personal config: no `plugins/` indirection, no framework. The one
convention worth preserving (now documented in `AGENTS.md`): **plugin keymaps live in
the module that owns the plugin**, so `remap.lua` stays generic-editor-only.

### 1.4 Cleanup applied

- `init.lua:3` / `lua/orloh/init.lua:14` — removed `print("hello")` (appeared on every
  startup and bypassed your mini.notify override).
- `options.lua` — `vim.opt.undodir = vim.fs.joinpath(vim.fn.stdpath("data"), "undodir")`
  (replaces `".."` string concatenation); removed `vim.opt.colorcolumn = "0"` ("0" is
  not a valid column reference — the default empty value is what you wanted); trailing
  whitespace; yank-highlight autocmd now under the `orloh-yank-highlight` augroup.
- `commands.lua` — two tab-indented lines unified to the file's 4-space style.
- `remap.lua` — "Paset" → "Paste"; `<leader>pv` gained a missing `desc`.
- `pick.lua` — "nota installed" → "not installed" (×2).
- Autocmds that persist across config reloads should always carry
  `group = vim.api.nvim_create_augroup("orloh-*", { clear = true })` — `:restart`
  starts a fresh process (no duplication today), but the groups make re-sourcing safe
  too. The new autocmds follow this pattern.

### 1.5 Treesitter: redundant resolution removed

`treesitter.lua` called `vim.treesitter.language.get_lang(ft)` and then
`pcall(vim.treesitter.language.add, lang)` before `vim.treesitter.start()`. Both steps
are redundant — `start(bufnr)` already resolves the filetype→language mapping and adds
the parser. The autocmd is now:

```lua
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("orloh-treesitter-start", { clear = true }),
    pattern = "*",
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
    end,
})
```

The `pcall` stays: it is the guard for filetypes whose parser is not installed (the
`main`-branch nvim-treesitter does not auto-start parsers and has no legacy
`ensure_installed`/`setup()` API — `install({...})` + this autocmd is the intended
pattern).

---

## 2. LSP & Autocompletion Optimization

### 2.1 The critical finding: clangd was missing entirely

`vim.lsp.enable("clangd")` was set, but clangd existed neither on PATH nor in Mason —
C buffers silently had no LSP at all (a missing server is a warning in
`:checkhealth`, never a startup error). Installed via `:MasonInstall clangd` (22.1.6).
Lesson: after any server change, run `:checkhealth vim.lsp`, not just "does nvim open".

### 2.2 Python: ruff now owns lint + format, pyright owns types

pyright has no `textDocument/formatting` capability — `<leader>f`
(`vim.lsp.buf.format`) was doing nothing in Python. The standard modern split
(pyright: types/hover/definitions; ruff: linting, formatting, organize-imports) is now
configured:

```lua
vim.lsp.config("pyright", {
    settings = {
        pyright = {
            disableOrganizeImports = true,  -- ruff owns imports
        },
    },
})

vim.lsp.config("ruff", {})
```

`vim.lsp.enable` now includes `"ruff"`. Verified headless: a `.py` buffer attaches
**both** `pyright` and `ruff`. This adds zero plugins — ruff is a Mason package.

### 2.3 Inlay hints: on where supported

clangd advertises `inlayHintProvider` and it is now enabled automatically:

```lua
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
```

Verified: `true` on a C buffer (clangd). The capability gate matters because
**pyright does not implement inlay hints** — grep of the 1.1.410 dist finds zero
occurrences of `inlayHint`; the hints you see in VS Code come from Pylance
(proprietary) or basedpyright (open fork). Since you edit Lua daily, lua_ls hints were
also switched on: `Lua = { hint = { enable = true } }` (verified `true` on
`lua/orloh/lsp.lua`). See §5.1 if you want them in Python.

### 2.4 clangd tuning for large C codebases

The lspconfig default `cmd` is bare `{ "clangd" }`. Now configured:

```lua
vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",        -- index in a background process; persistent .cache
        "--clang-tidy",              -- clang-tidy diagnostics inline
        "--completion-style=detailed", -- full signatures in completion (vs "bundled")
        "--header-insertion=iwyu",   -- auto-include what you use
    },
})
```

Notes for large projects:

- clangd finds code via `compile_commands.json`. With CMake:
  `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..`; the lspconfig header also documents
  symlinking it from a build dir into the project root.
- `--background-index` writes to `<build-dir>/.cache/clangd` — first open of a big
  repo is slow to reach full fidelity; subsequent opens are fast.
- Keep the default root-marker resolution (`.clangd`, `compile_commands.json`, …) —
  it is already correct from `lsp/clangd.lua`.

### 2.5 Autocompletion: enable the snippet engine you already ship

mini.completion's default snippet insert tries **mini.snippets first**, then falls
back to `vim.snippet.expand()`, then raw text (verified in
`mini.nvim/lua/mini/completion.lua:338-340, 565-570`). Without mini.snippets set up,
clangd/pyright snippet completions (function-call templates etc.) degrade. Since
mini.nvim is already installed, this costs one line in `completions.lua`:

```lua
require("mini.snippets").setup()
```

### 2.6 No redundant formatters/linters found

Post-change the toolchain is clean: clangd (C: format + clang-tidy), pyright (types
only), ruff (Python: one tool for lint + format — no black/isort/flake8 overlap),
lua_ls, bashls. No conflicts. The capabilities merge with
`mini.completion.get_lsp_capabilities()` is the correct pattern and was kept.

### 2.7 Free 0.11+ LSP defaults you may not know you have

No action needed — just awareness (verify with `<leader>pk`): `K` hover, `grr`
references, `gra` code action, `grn` rename, `gri` implementations, `gO` document
symbols, `[d` / `]d` diagnostic jump, `<C-W>d` diagnostic window. Your custom `gd`
sits fine alongside them.

---

## 3. Performance & Startup Time

Measured with `nvim --startuptime` (terminal UI, 6 runs):

- **Total: ~58–72 ms** — healthy; nothing here needs a lazy-loader.

Breakdown of the biggest contributors (from the log):

| Component | Time | Note |
|---|---|---|
| `vim.filetype` + core | ~7 ms | unavoidable |
| `require('orloh.lsp')` | ~13 ms | mason.setup() + nvim-lspconfig default configs |
| `require('orloh.pick')` | ~6 ms | mini.extra pickers registration |
| treesitter module + plugin | ~4 ms | `install()` is idempotent + async when parsers exist |

Assessment:

- **Eager loading all 7 plugins is the right call at this scale.** Adding lazy.nvim
  would trade real complexity for milliseconds you cannot feel — and `vim.pack` is
  deliberately minimal. Do not "modernize" this into a lazy loader.
- `vim.lsp.enable()` starts servers on matching filetypes only — nothing blocks
  startup waiting for a server. Verified: headless startup with no file exits in 0
  with no server processes.
- First-run `vim.pack.add()` clones block startup (expected, one-time, and the pcall
  guards in colors/pick/arrow/treesitter are what keep that first run from erroring).
- The removed `print("hello")` calls were the only true startup noise.
- `clipboard = unnamedplus` spawns a provider at first yank, not at startup —
  negligible here.
- `require("vim._core.ui2").enable({})` (experimental UI) works headless and adds no
  measurable cost. Keep it first in `init.lua` — it must initialize before the UI.

---

## 4. Keybindings & Workflow

### 4.1 Conflict fixed: `<leader>d` prefix stall

`<leader>d` (delete without yanking, `remap.lua`) and `<leader>df` (diagnostic float,
`lsp.lua`) shared a prefix, so every press of `<leader>d` waited out `timeoutlen`
(1000 ms default) to see whether `f` would follow. The diagnostic float now lives at
**`<leader>xd`**, joining your existing `<leader>xx` (diagnostics picker) under a
consistent `<leader>x*` diagnostics namespace. `<leader>d` now fires instantly.

### 4.2 Unreachable maps fixed: `]a` / `[a` for arrow files

`<C-S-P>` / `<C-S-N>` (arrow.lua) almost never fire: terminals transmit
`<C-S-p>`/`<C-S-n>` identically to `<C-p>`/`<C-n>` for most keys, so the shifted
mapping is unreachable in practice. Replaced with `]a` / `[a`, matching Neovim's
builtin next/prev idiom (`]b` buffers, `]q` quickfix, `]d` diagnostics) — and
freeing `<C-p>` (git files) from shadowing.

### 4.3 Kept, with notes

- `<C-ñ>` (arrow file 4) — works on your keyboard layout but will silently not exist
  on US-layout machines; fine for a personal config, worth knowing if a sync target
  ever changes.
- `<C-e>` as the arrow.nvim menu key overrides builtin scroll-down — deliberate, kept.
- `<C-c>` → `<Esc>` in insert mode — deliberate (makes `<C-c>` behave like `<Esc>`
  for completion/undo grouping), kept.
- `J`/`K` visual line-move, `n`/`N` centering, `<leader>s` substitution — all fine.

### 4.4 The two modern additions for your C/Python workflow (per your ask)

1. **Inlay hints** (§2.3) — a 0.11+ builtin you were not using; now on for clangd and
   lua_ls.
2. **mini.snippets** (§2.5) — proper LSP snippet expansion from the mini.nvim you
   already have installed.

Both applied. §5 lists the two bigger optional upgrades (basedpyright for Python
inlay hints; DAP for debugging).

---

## 5. Optional next steps (not applied)

### 5.1 Python inlay hints: swap pyright → basedpyright

basedpyright is a drop-in community fork that adds inlay hints (plus type-checking
improvements). If you want parity with clangd's hint experience in Python:

```lua
-- in lsp.lua: replace the pyright block with
vim.lsp.config("basedpyright", {})
-- and in vim.lsp.enable: replace "pyright" with "basedpyright"
```

Then `:MasonInstall basedpyright` and `:PackUpdate`-free — nothing else changes (it
speaks the same protocol). Ruff keeps owning lint/format/imports either way.

### 5.2 Debugging (DAP) for C and Python

Currently there is no debug story for either language. The conventional stack:

```lua
-- pack.lua (vim.pack.add):
"https://github.com/mfussenegger/nvim-dap",
"https://github.com/mfussenegger/nvim-dap-python",

-- a new lua/orloh/dap.lua + require in orloh/init.lua:
local dap = require("dap")
local dap_python = require("dap-python")

dap_python.setup("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python")
dap_python.test_runner = "pytest"

dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
    },
}
dap.configurations.c = {
    {
        name = "Launch binary",
        type = "codelldb",
        request = "launch",
        program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue/start" })
vim.keymap.set("n", "<leader>dt", dap_python.test_method, { desc = "DAP test method (pytest)" })
```

Requires `:MasonInstall debugpy codelldb`. This is the one addition where a new
plugin is genuinely warranted — there is no builtin DAP.

### 5.3 0.13 upgrade watch-list

When you move past 0.12: `vim.lsp.client()` replaces `get_client_by_id()`,
`vim.lsp.inlay.*` replaces `inlay_hint.*`, and `:PackDel`/`:PackUpdate` notes in
`commands.lua` may be removable. The AGENTS.md constraints section will need updating
in the same pass.

---

## Appendix A — verification log

Commands executed against the modified config (all exit 0 unless noted):

```
nvim --headless '+qa'                                  # clean startup, silent
nvim --headless '+MasonInstall ruff'  '+sleep 3000m' '+qa'   # ruff 0.16.5
nvim --headless '+MasonInstall clangd' '+sleep 3000m' '+qa'  # clangd 22.1.6
nvim --headless smoke.py +wait-for-clients            # attached: pyright, ruff
nvim --headless smoke.c  +wait-for-clients            # attached: clangd
#   inlay_hint.is_enabled({bufnr}) = true
#   exists(":LspClangdSwitchSourceHeader") = 2
nvim --headless lua/orloh/lsp.lua +wait-for-clients   # attached: lua_ls, inlay = true
nvim --startuptime (x6)                                # ~58–72 ms total
```

Static verifications:

- pyright 1.1.410 `dist/pyright-internal.js`: 0 matches for `inlayHint` (no inlay
  capability — §2.3).
- mini.completion source: `default_snippet_insert` prefers mini.snippets, falls back
  to `vim.snippet.expand` (§2.5).
- nvim-treesitter `main` branch: no auto-start FileType autocmd; `install()` is the
  entry point (§1.5).
- nvim-lspconfig `lsp/clangd.lua`: default `cmd = { 'clangd' }` (no flags — §2.4);
  buffer-local command is `LspClangdSwitchSourceHeader`.
- arrow.nvim `init.lua:79`: option is `always_show_path` (typo was silently ignored).

-- 42 School Norm support, scoped to the 42Madrid workspace.
-- Provides the 42 header (:Stdheader), norminette diagnostics (:Norminette) and
-- c_formatter_42 as a buffer-local <leader>f for C/header buffers in the project.

local M = {}

M.login = "orhernan"
M.mail = "orhernan@student.42madrid.com"
M.roots = { vim.fn.expand("~/42Madrid") }

local namespace = vim.api.nvim_create_namespace("orloh-norminette")

local group = vim.api.nvim_create_augroup("orloh-norm", { clear = true })

local function in_project(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return false
    end
    local path = vim.fn.fnamemodify(name, ":p")
    for _, root in ipairs(M.roots) do
        if path == root or path:find(root .. "/", 1, true) == 1 then
            return true
        end
    end
    return false
end

local function require_project()
    if in_project(vim.api.nvim_get_current_buf()) then
        return true
    end
    vim.notify("42 norm: buffer is outside " .. table.concat(M.roots, ", "), vim.log.levels.WARN)
    return false
end

local ascii = {
    "        :::      ::::::::",
    "      :+:      :+:    :+:",
    "    +:+ +:+         +:+  ",
    "  +#+  +:+       +#+     ",
    "+#+#+#+#+#+   +#+        ",
    "     #+#    #+#          ",
    "    ###   ########.fr    ",
}

local START, STOP, FILL, LENGTH, MARGIN = "/*", "*/", "*", 80, 5

local function textline(left, right)
    local max_left = LENGTH - MARGIN * 2 - #right
    if #left > max_left then
        left = left:sub(1, max_left)
    end
    local spaces = LENGTH - MARGIN * 2 - #left - #right
    if spaces < 0 then
        spaces = 0
    end
    return START
        .. string.rep(" ", MARGIN - #START)
        .. left
        .. string.rep(" ", spaces)
        .. right
        .. string.rep(" ", MARGIN - #STOP)
        .. STOP
end

local function filename(bufnr)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr or 0), ":t")
end

local function header_line(n, bufnr)
    if n == 1 or n == 11 then
        return START .. " " .. string.rep(FILL, LENGTH - #START - #STOP - 2) .. " " .. STOP
    elseif n == 2 or n == 10 then
        return textline("", "")
    elseif n == 3 or n == 5 or n == 7 then
        return textline("", ascii[n - 2])
    elseif n == 4 then
        return textline(filename(bufnr), ascii[n - 2])
    elseif n == 6 then
        local author = "By: " .. M.login .. " <" .. M.mail .. ">"
        if #author > LENGTH - MARGIN * 2 - #ascii[n - 2] then
            author = "By: " .. M.mail
        end
        return textline(author, ascii[n - 2])
    elseif n == 8 then
        return textline("Created: " .. os.date("%Y/%m/%d %H:%M:%S") .. " by " .. M.login, ascii[n - 2])
    elseif n == 9 then
        return textline("Updated: " .. os.date("%Y/%m/%d %H:%M:%S") .. " by " .. M.login, ascii[n - 2])
    end
end

local function has_header(bufnr)
    local line9 = vim.api.nvim_buf_get_lines(bufnr, 8, 9, false)[1]
    return line9 ~= nil and line9:find("^/%*   Updated: ") ~= nil
end

function M.update_header(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) or not in_project(bufnr) or not has_header(bufnr) then
        return
    end
    local name_line = header_line(4, bufnr)
    if vim.api.nvim_buf_get_lines(bufnr, 3, 4, false)[1] ~= name_line then
        vim.api.nvim_buf_set_lines(bufnr, 3, 4, false, { name_line })
    end
    vim.api.nvim_buf_set_lines(bufnr, 8, 9, false, { header_line(9, bufnr) })
end

function M.stdheader()
    if not require_project() then
        return
    end
    if has_header(0) then
        vim.api.nvim_buf_set_lines(0, 3, 4, false, { header_line(4) })
        vim.api.nvim_buf_set_lines(0, 8, 9, false, { header_line(9) })
    else
        local lines = {}
        for i = 1, 11 do
            lines[i] = header_line(i)
        end
        lines[12] = ""
        vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
        vim.api.nvim_win_set_cursor(0, { 12, 0 })
    end
end

function M.format()
    local bufnr = vim.api.nvim_get_current_buf()
    local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
    local out = vim.fn.system({ "c_formatter_42" }, input)
    if vim.v.shell_error ~= 0 then
        vim.notify("c_formatter_42 failed:\n" .. out, vim.log.levels.ERROR)
        return
    end
    local lines = vim.split(out, "\n", { plain = true })
    if lines[#lines] == "" then
        table.remove(lines)
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { math.min(cursor[1], #lines), cursor[2] })
end

function M.check()
    if not require_project() then
        return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then
        vim.notify("42 norm: buffer has no file on disk", vim.log.levels.WARN)
        return
    end
    local out = vim.fn.system({ "norminette", "-f", "json", file })
    local json_start = out:find("{", 1, true)
    local data = json_start and vim.json.decode(out:sub(json_start)) or nil
    if not data then
        vim.notify("norminette failed:\n" .. out, vim.log.levels.ERROR)
        return
    end

    local diagnostics, seen = {}, {}
    for _, f in ipairs(data.files or {}) do
        for _, err in ipairs(f.errors or {}) do
            for _, h in ipairs(err.highlights or {}) do
                local lnum = math.max((h.lineno or 1) - 1, 0)
                local col = math.max((h.column or 1) - 1, 0)
                local key = lnum .. ":" .. col .. ":" .. err.name
                if not seen[key] then
                    seen[key] = true
                    diagnostics[#diagnostics + 1] = {
                        bufnr = bufnr,
                        lnum = lnum,
                        col = col,
                        message = err.name .. ": " .. err.text,
                        severity = err.level == "Error" and vim.diagnostic.severity.ERROR
                            or vim.diagnostic.severity.WARN,
                        source = "norminette",
                    }
                end
            end
        end
    end
    vim.diagnostic.set(namespace, bufnr, diagnostics)
    vim.notify(
        ("norminette: %d issue(s) in %s"):format(#diagnostics, vim.fn.fnamemodify(file, ":t")),
        #diagnostics > 0 and vim.log.levels.WARN or vim.log.levels.INFO
    )
end

vim.api.nvim_create_user_command("Stdheader", M.stdheader, { desc = "Insert or refresh the 42 header" })
vim.api.nvim_create_user_command("Norminette", M.check, { desc = "Run norminette on the current buffer" })

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "c", "h" },
    desc = "42 norm buffer-local maps inside the 42Madrid workspace",
    callback = function(args)
        if not in_project(args.buf) then
            return
        end
        vim.bo[args.buf].expandtab = false
        vim.bo[args.buf].tabstop = 4
        vim.bo[args.buf].shiftwidth = 4
        vim.bo[args.buf].softtabstop = 0
        vim.keymap.set("n", "<leader>f", M.format, { buffer = args.buf, desc = "Format with c_formatter_42" })
        vim.keymap.set("n", "<leader>xn", M.check, { buffer = args.buf, desc = "Run norminette" })
        vim.keymap.set("n", "<leader>xh", M.stdheader, { buffer = args.buf, desc = "Insert/refresh 42 header" })
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = { "*.c", "*.h" },
    desc = "Refresh the 42 header Updated line on save",
    callback = function(args)
        M.update_header(args.buf)
    end,
})

return M

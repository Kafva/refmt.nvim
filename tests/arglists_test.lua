require('refmt').setup {}

local M = {}

local tsst = require 'tsst'

M.testcases = {}

-- Add required parsers
vim.treesitter.language.add('c', { path = "./tests/parser/c.so" })
vim.treesitter.language.add('rust', { path = "./tests/parser/rust.so" })
vim.treesitter.language.add('zig', { path = "./tests/parser/zig.so" })

M.before_each = function()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()
end

table.insert(M.testcases, {
    desc = 'Unfold and refold function parameters',
    fn = function()
        vim.cmd "edit tests/files/arglists_input.zig"
        local initial_lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        -- Unfold into multiple lines
        vim.api.nvim_win_set_cursor(0, { 3, 30 })
        require('refmt').convert_between_single_and_multiline_argument_lists()

        vim.cmd "silent write!"
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/arglists_output.zig", lines)
    end,
})

return M

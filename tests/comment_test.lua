require('refmt').setup {}

local M = {}

local tsst = require 'tsst'

M.testcases = {}

-- Add required parsers
vim.treesitter.language.add('c', { path = "./tests/parser/c.so" })

M.before_each = function()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''
end

table.insert(M.testcases, {
    desc = 'Convert multiline // comments into /** ... */ comments',
    fn = function()
        vim.cmd [[edit tests/files/comment_input.c]]

        -- XXX: The linecount of the file increases by 2 for each
        -- convert_comment_slash_to_asterisk() call on multiple lines
        vim.api.nvim_win_set_cursor(0, { 3, 0 })
        require('refmt').convert_comment_slash_to_asterisk()

        vim.api.nvim_win_set_cursor(0, { 11, 12 })
        require('refmt').convert_comment_slash_to_asterisk()

        vim.api.nvim_win_set_cursor(0, { 22, 10 })
        require('refmt').convert_comment_slash_to_asterisk()

        vim.api.nvim_win_set_cursor(0, { 32, 0 })
        require('refmt').convert_comment_slash_to_asterisk()

        vim.cmd [[silent write!]]
        local lines = vim.api.nvim_buf_get_lines(0, 0, vim.fn.line('$'), true)

        tsst.assert_eql_file("tests/files/comment_output.c", lines)
    end,
})

return M

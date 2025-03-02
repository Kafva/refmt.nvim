require('refmt').setup {}

local M = {}

local tsst = require 'tsst'

M.testcases = {}

M.before_each = function()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''
end

table.insert(M.testcases, {
    desc = 'Convert a multiline // comment',
    fn = function()
    end,
})

return M

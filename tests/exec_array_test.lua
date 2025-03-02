require('refmt').setup {}

local M = {}

local tsst = require 'tsst'

M.testcases = {}

-- Add required parsers
vim.treesitter.language.add('bash', { path = "./tests/parser/bash.so" })

M.before_each = function()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''
end

table.insert(M.testcases, {
    desc = 'Convert to an exec(...) array in a shell script',
    fn = function()
        vim.cmd [[edit tests/files/exec_array_input.sh]]

        tsst.assert_eql_file("tests/files/exec_array_output.sh", lines)
    end,
})

return M

M = {}

function M.load_parsers()
    -- Load all required parsers
    vim.treesitter.language.add('c', { path = "./tests/parser/c.so" })
    vim.treesitter.language.add('rust', { path = "./tests/parser/rust.so" })
    vim.treesitter.language.add('zig', { path = "./tests/parser/zig.so" })
    vim.treesitter.language.add('bash', { path = "./tests/parser/bash.so" })

    vim.treesitter.language.register("bash", "sh")
end

function M.before_each()
    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()

    -- Some translations are based of a preset shiftwidth
    vim.o.sw = 4
end


return M

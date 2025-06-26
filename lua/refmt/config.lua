local M = {}

---@enum ExprType
ExprType = {
    FUNC_DEF = 'func_def',
    FUNC_CALL = 'func_call',
    LIST = 'list',
    DEREF_CALL = 'deref_call',
    DEREF_CALL_ARGS = 'deref_call_args',
    DEREF_OPERATOR = 'deref_operator',
}

---@type RefmtOptions
M.default_opts = {
    -- Enable default keybindings?
    default_bindings = true,
    -- Enable trace logging?
    trace = false,
    -- Filetypes to insert trailing commas for when expanding expressions
    -- onto multiple lines
    trailing_comma_filetypes = {
        [ExprType.FUNC_DEF] = {
            'zig',
            'rust',
            'go',
        },
        [ExprType.FUNC_CALL] = {},
        [ExprType.LIST] = {
            'zig',
            'lua',
            'python',
            'go',
        },
    },
    -- Filetypes that use {...} instead of [...] for arrays
    curly_bracket_filetypes = {
        'c',
        'cpp',
        'zig',
        'lua',
        'go',
    },
    -- Shell script filetypes
    shell_filetypes = {
        'sh',
        'bash',
        'zsh',
    },
    -- Filetypes that need a '\' at EOL for dereferencing on multiple lines
    multiline_escaped_filetypes = {
        'python',
    },
    multiline_deref_unsupported_filetypes = {
        'go',
    },
    -- Recognized `TSNode` parent types when converting between single and
    -- multiline expressions per expression type and language (excluding shell).
    node_types = {
        [ExprType.FUNC_DEF] = {
            default = { 'parameters' },
            zig = { 'parameters' },
            rust = { 'parameters' },
            java = { 'method_declaration', 'formal_parameters' },
            c = { 'parameter_list' },
            cpp = { 'parameter_list' },
            go = { 'parameter_list' },
            dart = { 'formal_parameter_list' },
            kotlin = { 'function_value_parameters' },
            swift = { 'function_declaration' },
            typescript = { 'formal_parameters' },
            typescriptreact = { 'formal_parameters' },
            javascript = { 'formal_parameters' },
            javascriptreact = { 'formal_parameters' },
        },
        [ExprType.FUNC_CALL] = {
            default = { 'arguments' },
            zig = { 'call_expression' },
            rust = { 'arguments' },
            c = { 'argument_list' },
            cpp = { 'argument_list' },
            go = { 'argument_list' },
            python = { 'argument_list' },
            swift = { 'value_arguments' },
        },
        [ExprType.LIST] = {
            default = { 'array' },
            typescript = { 'array' },
            python = { 'list' },
            lua = { 'table_constructor' },
            swift = { 'array_literal' },
            rust = { 'array_expression', 'field_initializer_list' },
            c = { 'initializer_list' },
            cpp = { 'initializer_list' },
            zig = { 'initializer_list' },
            go = { 'literal_value' },
        },
        [ExprType.DEREF_CALL] = {
            default = { 'call_expression' },
            python = { 'call' },
            lua = { 'function_call' },
        },
        [ExprType.DEREF_CALL_ARGS] = {
            default = { 'arguments' },
            python = { 'argument_list' },
            swift = { 'value_arguments', 'lambda_literal' },
            kotlin = { 'value_arguments', 'annotated_lambda' },
            zig = {},
        },
        [ExprType.DEREF_OPERATOR] = {
            default = { '.' },
            rust = { '.', '::' },
            c = { '.', '->' },
            cpp = { '.', '->', '::' },
        },
    },
}

---@param user_opts RefmtOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend('force', M.default_opts, user_opts or {})

    -- Expose configuration variables
    for k, v in pairs(opts) do
        M[k] = v
    end

    -- stylua: ignore start
    if opts and opts.default_bindings then
        vim.keymap.set("n", "tl", require('refmt').convert_between_single_and_multiline_parameter_lists,
                       {desc = "Toggle between a single line and multiline list of parameters"})

        vim.keymap.set("n", "t.", require('refmt').convert_between_single_and_multiline_deref,
                       {desc = "Toggle between a single line and multiline field dereferencing"})

        vim.keymap.set("n", "ta", require('refmt').convert_between_command_and_exec_array,
                      {desc = "Convert between a bash command and an exec(...) array"})

        vim.keymap.set("n", "tc", require('refmt').convert_comment_slash_to_asterisk,
                       {desc = "Convert '// ... ' comments into '/** ... */'"})
    end
    -- stylua: ignore end
end

---@param exprtype ExprType
---@return string[]
function M.get_node_types(exprtype)
    return M.node_types[exprtype][vim.o.ft] or M.node_types[exprtype]['default']
end

return M

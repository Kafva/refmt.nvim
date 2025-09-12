# refmt.nvim
Neovim plugin to reformat code with treesitter.
You need to have [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and
relevant parsers installed for the plugin to work.

## Setup

```lua
require 'refmt'.setup{
  -- Disable to configure your own mappings
  default_bindings = true
}
```

## Features

* Unfold and refold function parameters, function calls and list items (see example in video). Bound to `tl` by default.
* Unfold and refold dereferencing of fields on objects, i.e. split `a.b.c.d.e` onto
  multiple lines and vice versa.
* Unfold and refold attributes of "xml-like" elements.
* Convert `// ... ` comments into `/** ... */`. Bound to `tc` by default.
* Convert between a shell command and an array of strings, useful when converting between a shell command and e.g. a `subprocess.run(...)` call in Python. Bound to `ta` by default.

https://github.com/user-attachments/assets/966ab6f5-e468-4d6d-9777-a740fc71cc5a


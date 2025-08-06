#!/usr/bin/env bash
set -e

die() { printf "$1\n" >&2 && exit 1; }

if [ "$(basename $PWD)" != refmt.nvim ]; then
    die "Run from project root"
fi

# Clone the test runner
if [ ! -e "tests/tsst.nvim" ]; then
    git clone --depth 1 https://github.com/kafva/tsst.nvim.git tests/tsst.nvim
fi

# Use local installation of treesitter parsers in .testenv
TS_PATH=$(find $HOME/.local/share/nvim -type d -name nvim-treesitter | head -n1)
[ -d "$TS_PATH" ] || die "Cound not find nvim-treesitter installation"
ln -fns $TS_PATH/parser tests/parser

# Run tests
if [ $# = 0 ]; then
    tests/tsst.nvim/tsst || :
    git checkout tests/files 2> /dev/null
else
    tests/tsst.nvim/tsst $@
fi

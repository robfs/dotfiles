-- General indentation settings
vim.opt.tabstop = 4 -- Number of spaces that a <Tab> in the file counts for
vim.opt.shiftwidth = 4 -- Number of spaces to use for each step of (auto)indent
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.smartindent = true -- Smart autoindenting when starting a new line
vim.opt.autoindent = true -- Copy indent from current line when starting a new line

vim.opt.number = true
vim.opt.relativenumber = true
vim.o.scrolloff = 10
vim.o.clipboard = 'unnamedplus'

vim.cmd.colorscheme 'catppuccin-macchiato'

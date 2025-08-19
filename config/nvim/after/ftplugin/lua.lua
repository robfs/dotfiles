local set = vim.opt_local

set.shiftwidth = 2

-- Keymaps to run lua code live.
vim.keymap.set('n', '<space>x', ':.lua<CR>')
vim.keymap.set('v', '<space>x', ':lua<CR>')

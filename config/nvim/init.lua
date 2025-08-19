vim.g.mapleader = 'space'
vim.g.maplocalleader = 'space'
vim.g.python3_host_prog = '~/nvimvenv/.venv/bin/python'

if vim.fn.executable 'wl-copy' == 1 and vim.fn.executable 'wl-paste' == 1 then
  vim.g.clipboard = {
    name = 'wl-clipboard',
    copy = {
      ['+'] = 'wl-copy',
      ['*'] = 'wl-copy --primary',
    },
    paste = {
      ['+'] = 'wl-paste --no-newline',
      ['*'] = 'wl-paste --no-newline --primary',
    },
    cache_enabled = 0,
  }
end

require 'config.lazy'
require 'config.options'
require 'config.keymaps'

-- Sourcing keymap
vim.keymap.set('n', '<leader><leader>x', '<cmd>source %<CR>')
vim.keymap.set('n', '-', '<cmd>Oil<CR>', {})
-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text.',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Python-specific settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true
vim.opt_local.smartindent = true
-- vim.opt_local.textwidth = 88 -- PEP 8 recommends 79, but many use 88 for black compatibility
vim.opt_local.colorcolumn = '88'

-- Enable treesitter-based indentation for Python
vim.opt_local.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

local terminal_opts = { win = { style = { border = 'rounded' } }, auto_close = false }

local function uv_run_file(opts)
  local path = opts.args
  if path == nil or path == '' then
    path = vim.api.nvim_buf_get_name(0)
  end
  local cmd = 'uv run ' .. path
  require('snacks').terminal.open(cmd, terminal_opts)
end

local function textual_run_file(opts)
  local path = opts.args
  if path == nil or path == '' then
    path = vim.api.nvim_buf_get_name(0)
  end
  local cmd = 'uv run textual run --dev ' .. path
  require('snacks').terminal.open(cmd, terminal_opts)
end

local uv_run_selection = function()
  -- yank selection to register v
  vim.cmd 'normal! "vy'
  local cmd = "uv run python -c '" .. vim.fn.getreg 'v' .. "'"
  require('snacks').terminal.open(cmd, terminal_opts)
end

local textual_colors = function()
  local cmd = 'uv run textual colors'
  require('snacks').terminal.open(cmd, terminal_opts)
end

-- User commands to run python files
vim.api.nvim_create_user_command('UVRunFile', uv_run_file, { nargs = '?', complete = 'file' })
vim.api.nvim_create_user_command('UVRunSelection', uv_run_selection, {})
vim.api.nvim_create_user_command('TextualColors', textual_colors, {})
vim.api.nvim_create_user_command('TextualRunDev', textual_run_file, { nargs = '?', complete = 'file' })

-- Keymaps
vim.keymap.set('n', '<leader>x', '<cmd>UVRunFile<CR>', { desc = 'UV run file' })
vim.keymap.set('v', '<leader>x', '<cmd>UVRunSelection<CR>', { desc = 'UV run selection' })
vim.keymap.set('n', '<leader>ta', '<cmd>TextualRunDev app.py<CR>', { desc = 'Textual run app.py' })

local terminal_opts = { win = { style = { border = 'rounded' } }, auto_close = false }

local function shell_run_file(opts)
  local path = opts.args
  if path == nil or path == '' then
    path = vim.api.nvim_buf_get_name(0)
  end
  local cmd = path
  require('snacks').terminal.open(cmd, terminal_opts)
end

vim.api.nvim_create_user_command('ShellRunFile', shell_run_file, { nargs = '?', complete = 'file' })
vim.keymap.set('n', '<leader>x', '<cmd>ShellRunFile<CR>', { desc = 'Run shell script' })

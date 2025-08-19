return {
  {
    'github/copilot.vim',
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap('i', '<C-n>', 'copilot#Next()', { expr = true, silent = true })
      vim.api.nvim_set_keymap('i', '<C-p>', 'copilot#Previous()', { expr = true, silent = true })
      vim.api.nvim_set_keymap('i', '<C-y>', 'copilot#Accept("<CR>")', { expr = true, silent = true })
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = {
      window = {
        layout = 'vertical',
        width = 0.4,
      },
    },
  },
}

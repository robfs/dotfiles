return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',
  -- event = {
  --   'BufReadPre $VAULT/*.md',
  --   'BufNewFile $VAULT/*.md',
  -- },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    workspaces = {
      { name = 'personal', path = os.getenv 'VAULT' or vim.fn.expand '~/vault' },
    },
    ui = { enable = false },
    completion = { blink = true, nvim_cmp = false },
    picker = { name = 'snacks.pick' },
    legacy_commands = false,
  },
}

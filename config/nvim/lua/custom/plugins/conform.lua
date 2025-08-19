return {
  {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
      require('conform').setup {
        formatters_by_ft = {
          lua = { 'stylua' },
          python = { 'ruff_format', 'ruff_organize_imports' },
          html = { 'prettier' },
        },
        formatters = {
          ruff_format = {
            command = 'ruff',
            args = { 'format', '--stdin-filename', '$FILENAME', '-' },
            stdin = true,
          },
          ruff_organize_imports = {
            command = 'ruff',
            args = { 'check', '--select', 'I', '--fix', '--stdin-filename', '$FILENAME', '-' },
            stdin = true,
          },
        },
        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 2000,
          lsp_format = 'fallback',
          quiet = false,
        },
        -- Add manual format keymap
        default_format_opts = {
          timeout_ms = 3000,
          async = false,
          quiet = false,
          lsp_format = 'fallback',
        },
      }

      -- Add keymap for manual formatting
      vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
        require('conform').format { async = true }
      end, { desc = '[C]ode [F]ormat' })
    end,
  },
}

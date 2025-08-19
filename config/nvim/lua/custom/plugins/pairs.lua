return {
  {
    'saghen/blink.pairs',
    version = '*', -- (recommended) only required with prebuilt binaries
    dependencies = 'saghen/blink.download',
    --- @module 'blink.pairs'
    --- @type blink.pairs.Config
    opts = {
      mappings = {
        enabled = true,
        disabled_filetypes = {},
        pairs = {},
      },
      highlights = {
        enabled = true,
        -- requires require('vim._extui').enable({}), otherwise has no effect
        -- cmdline = true,
        groups = {
          'BlinkPairsOrange',
          'BlinkPairsPurple',
          'BlinkPairsBlue',
        },
        -- unmatched_group = 'BlinkPairsUnmatched',

        -- highlights matching pairs under the cursor
        matchparen = {
          enabled = true,
          -- known issue where typing won't update matchparen highlight, disabled by default
          -- cmdline = false,
          group = 'BlinkPairsMatchParen',
        },
      },
      debug = false,
    },
  },
}

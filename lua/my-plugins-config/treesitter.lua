local treesitter = require('nvim-treesitter.configs')

local config = {
  ensure_installed = { 'c', 'lua', 'rust', 'nix', 'go', 'python' },

  highlight = {
    enable = true,
  }
}

treesitter.setup(config)


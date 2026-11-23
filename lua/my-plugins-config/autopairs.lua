local autopairs = require('nvim-autopairs')

autopairs.setup({
  check_ts = true,
  ts_config = {
    lua = {'string'},
    javascript = {'template_string'},
    python = {'string'},
  },

  -- Enable wrapping in visual mode
  map_c_w = false,
  map_cr = true,
  map_c_h = false,
  enable_check_bracket_line = false,
})

-- IMPORTANT: Map brackets in visual mode to wrap
local remap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Visual mode mappings for wrapping
remap('v', '(', '<ESC>`>a)<ESC>`<i(<ESC>', opts)
remap('v', '[', '<ESC>`>a]<ESC>`<i[<ESC>', opts)
remap('v', '{', '<ESC>`>a}<ESC>`<i{<ESC>', opts)
remap('v', '"', '<ESC>`>a"<ESC>`<i"<ESC>', opts)
remap('v', "'", "<ESC>`>a'<ESC>`<i'<ESC>", opts)
remap('v', '`', '<ESC>`>a`<ESC>`<i`<ESC>', opts)

-- Auto-add brackets after autocomplete
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

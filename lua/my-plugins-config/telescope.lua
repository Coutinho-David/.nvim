require('telescope').setup({

  defaults = {
    prompt_prefix = '> ',
    color_devicons = true,

    file_previewer = require("telescope.previewers").vim_buffer_cat.new,
    grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
    qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
  },
  extensions = {
      fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
        },
    },
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>gd', builtin.lsp_definitions, { desc = "LSP Definitions" })
vim.keymap.set('n', '<leader>gr', builtin.lsp_references, { desc = "LSP References" })
vim.keymap.set('n', '<leader>gi', builtin.lsp_implementations, { desc = "LSP Implementations" })
vim.keymap.set('n', '<leader>ci', vim.lsp.buf.incoming_calls, { desc = "Incoming Calls" })
vim.keymap.set('n', '<leader>co', vim.lsp.buf.outgoing_calls, { desc = "Outgoing Calls" })

require("telescope").load_extension("fzy_native")
require("telescope").load_extension("git_worktree")

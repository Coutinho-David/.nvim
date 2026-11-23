require("my-plugins-config.telescope")
require("my-plugins-config.harpoon")
require("my-plugins-config.lsp")
require("my-plugins-config.lualine")
require("my-plugins-config.toggleterm")
require("my-plugins-config.which-key")
require("my-plugins-config.nvim-tree")
require("my-plugins-config.autopairs")
require("my-plugins-config.dap")

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local opts = { buffer = args.buf }

    -- 'K' shows the documentation hover popup. Bordered and focusable so you can
    -- <C-w>w into it and scroll long docstrings.
    vim.keymap.set('n', 'K', function()
      vim.lsp.buf.hover({ border = 'rounded', max_width = 100, max_height = 25 })
    end, opts)

    -- Go to definition (very useful alongside documentation)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)

    -- Signature help while typing/inspecting arguments
    vim.keymap.set('n', '<C-k>', function()
      vim.lsp.buf.signature_help({ border = 'rounded' })
    end, opts)

    -- Inlay hints on by default where the server supports them
    if client and client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

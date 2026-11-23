local cmp = require("cmp")
local cmp_select = {behavior = cmp.SelectBehavior.Select}

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  sources = {
    { name = 'path' },
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lua' },
    { name = 'buffer' },
    { name = 'luasnip' }
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ["<Up>"] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ["<Down>"] = cmp.mapping.select_next_item(cmp_select),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  formatting = {
    fields = {'menu', 'abbr', 'kind'},
    format = function(entry, item)
      local menu_icon = {
        nvim_lsp = 'λ',
        vsnip = '⋗',
        buffer = 'Ω',
        path = '🖫',
      }
      item.menu = menu_icon[entry.source.name]
      return item
    end,
  },
})

-- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local py = require("my-plugins-config.python")

require("mason").setup()

-- mason-lspconfig v2 dropped `handlers` and `automatic_installation`. Passing them is
-- silently ignored, so servers were started by `automatic_enable` with the *default*
-- capabilities and nvim-cmp's extra capabilities were never advertised.
-- v2 API: ensure_installed + automatic_enable, with per-server overrides declared
-- through vim.lsp.config (nvim 0.11).
require("mason-lspconfig").setup({
  ensure_installed = {
    "pyright",     -- python types, hover, go-to-definition
    "ruff",        -- python lint + format (fast)
    "lua_ls",
    "bashls",
    "jsonls",
    "yamlls",
    "dockerls",
  },
  -- jdtls is driven by nvim-jdtls in ftplugin/java.lua, not by vim.lsp.enable
  automatic_enable = { exclude = { "jdtls" } },
})

-- Applies to every server, including ones enabled automatically by mason-lspconfig.
vim.lsp.config("*", { capabilities = capabilities })

-- ---------------------------------------------------------------------------
-- Python
-- ---------------------------------------------------------------------------
vim.lsp.config("pyright", {
  before_init = function(_, config)
    -- Point pyright at the project's virtualenv. A pyrightconfig.json or a
    -- [tool.pyright] block in pyproject.toml overrides this, which is what you
    -- want for a venv in a non-standard place.
    local python = py.interpreter(config.root_dir)
    config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
      python = { pythonPath = python },
    })
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "standard",
        autoSearchPaths = true,
        -- read docstrings and infer types from library *source* when a package
        -- ships no stubs; this is what makes K useful on volatility3
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        inlayHints = { variableTypes = true, functionReturnTypes = true },
      },
    },
  },
})

-- ruff answers textDocument/hover with nothing useful (it only documents noqa codes)
-- and would otherwise compete with pyright for the K popup.
vim.lsp.config("ruff", {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
  init_options = { settings = { lineLength = 120 } },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

vim.api.nvim_create_user_command("PyrightVenv", function()
  py.clear_cache()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })[1]
  print("interpreter: " .. py.interpreter(client and client.config.root_dir or nil))
  vim.cmd("LspRestart pyright")
end, { desc = "Re-detect the Python venv and restart pyright" })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(e)
    local opts = {remap = false}
    local bind = vim.keymap.set
      bind('n', '<leader>cd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
      bind('n', '<leader>cD', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
      bind('n', '<leader>ci', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
      bind('n', '<leader>cs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      bind('n', '<leader>cr', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
      bind('n', '<leader>ch', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
      bind('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
      bind('n', '<leader>cf', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    -- vim.lsp.diagnostic.goto_next was removed in nvim 0.11
    bind('n', '<leader>cn', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    bind('n', '<leader>cp', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
    bind('n', '<leader>cx', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)
    bind('n', '<leader>ct', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
    end, opts)
    bind({ 'n', 'v' }, '<leader>cF', function() vim.lsp.buf.format({ async = true }) end, opts)
  end
})

vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = '●' },
    signs = true,
    -- re-linting on every keystroke made pyright report half-typed lines as errors
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      border = 'rounded',
      source = true,     -- 'always' was deprecated in nvim 0.10
      header = '',
      prefix = '',
    },
})

vim.o.signcolumn = 'yes'
vim.o.updatetime = 300

-- Show the diagnostic under the cursor, but never on top of an open hover/float,
-- which is what made K look like it "returned nothing".
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= '' then
        return
      end
    end
    vim.diagnostic.open_float(nil, { focusable = false, scope = 'cursor' })
  end,
})

local dap = require("dap")
local dapui = require("dapui")

-- ============================================================
-- Mason DAP: auto-install debug adapters
-- ============================================================
require("mason-nvim-dap").setup({
  ensure_installed = {
    "js",       -- js-debug-adapter (JS/TS/Node)
    "python",   -- debugpy
    "codelldb", -- C/C++/Rust via codelldb
    "javadbg",  -- java-debug-adapter
    "javatest", -- java-test
  },
  automatic_installation = true,
  handlers = {}, -- use default handlers to auto-configure adapters
})

-- ============================================================
-- DAP UI setup
-- ============================================================
dapui.setup({
  icons = { expanded = "-", collapsed = "+", current_frame = ">" },
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.4 },
        { id = "breakpoints", size = 0.15 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.2 },
      },
      position = "left",
      size = 45,
    },
    {
      elements = {
        { id = "repl", size = 0.5 },
        { id = "console", size = 0.5 },
      },
      position = "bottom",
      size = 12,
    },
  },
})

-- Auto open/close DAP UI when debugging starts/stops
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

-- ============================================================
-- Breakpoint signs
-- ============================================================
vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "R", texthl = "DiagnosticError", linehl = "", numhl = "" })

-- Highlight for the current stopped line
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#304030" })

-- ============================================================
-- DAP Configurations (launch profiles)
-- ============================================================

-- JavaScript / TypeScript (Node.js)
-- mason-nvim-dap auto-configures the "pwa-node" adapter via js-debug-adapter.
-- These configurations define HOW to launch/attach.
for _, lang in ipairs({ "javascript", "typescript" }) do
  dap.configurations[lang] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file (Node)",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file with ts-node",
      runtimeExecutable = "npx",
      runtimeArgs = { "ts-node" },
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      resolveSourceMapLocations = {
        "${workspaceFolder}/**",
        "!**/node_modules/**",
      },
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to running Node process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

-- Python
-- mason-nvim-dap auto-configures the "python" adapter via debugpy.
dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch current file",
    program = "${file}",
    -- Same venv resolution as pyright, so you debug with the interpreter you
    -- are getting completions from.
    pythonPath = function()
      return require("my-plugins-config.python").interpreter(vim.fn.getcwd())
    end,
    justMyCode = false,
  },
}

-- C / C++
-- mason-nvim-dap auto-configures the "codelldb" adapter.
for _, lang in ipairs({ "c", "cpp" }) do
  dap.configurations[lang] = {
    {
      type = "codelldb",
      request = "launch",
      name = "Launch executable",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
    {
      type = "codelldb",
      request = "attach",
      name = "Attach to process",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

-- Java
-- The "javadbg" adapter uses the java-debug-adapter jar.
-- mason-nvim-dap registers it as "java". You need jdtls running for full
-- support, but these configs work for standalone programs too.
-- Java
-- ==========
dap.adapters.java = function(callback)
  vim.lsp.buf_request(0, "workspace/executeCommand",
    { command = "vscode.java.startDebugSession" },
    function(err, port)
      assert(not err, vim.inspect(err))
      callback({
        type = "server",
        host = "127.0.0.1",
        port = port,
      })
    end
  )
end

dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Attach to remote JVM",
    hostName = "localhost",
    port = function()
      return tonumber(vim.fn.input("Debug port: ", "5005"))
    end,
  },
  {
    type = "java",
    request = "launch",
    name = "Launch Launcher",
    mainClass = "pt.up.fe.comp2026.Launcher",
    projectName = "comp2026-11e",
  },
}

-- ==================================================
-- Keybindings  (<leader>b = debug)
-- Registered through which-key v3 so they show in the popup
-- ============================================================
local wk = require("which-key")

wk.add({
  { "<leader>b", group = "Debug (DAP)" },

  -- Breakpoints
  { "<leader>bb", dap.toggle_breakpoint, desc = "Toggle breakpoint" },
  { "<leader>bB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional breakpoint" },
  { "<leader>bl", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, desc = "Log point" },

  -- Execution
  { "<leader>bc", dap.continue, desc = "Continue / Start" },
  { "<leader>bn", dap.step_over, desc = "Step over" },
  { "<leader>bi", dap.step_into, desc = "Step into" },
  { "<leader>bo", dap.step_out, desc = "Step out" },
  { "<leader>br", dap.restart, desc = "Restart" },
  { "<leader>bq", dap.terminate, desc = "Terminate" },

  -- UI
  { "<leader>bu", dapui.toggle, desc = "Toggle DAP UI" },
  { "<leader>be", dapui.eval, desc = "Eval expression", mode = { "n", "v" } },
  { "<leader>bR", function() dap.repl.open() end, desc = "Open REPL" },
})

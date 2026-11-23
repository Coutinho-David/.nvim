-- Locate the Python interpreter a project should be analysed/debugged with.
--
-- Without this, pyright runs against the system interpreter and every import from a
-- project virtualenv resolves to Unknown, which silently kills hover, go-to-definition
-- and type diagnostics for third-party code.
--
-- Search order:
--   1. $VIRTUAL_ENV          (an activated venv always wins)
--   2. <root>/{.venv,venv,env,.env}
--   3. <root>/*/{...}        one level down   (e.g. backend/.venv)
--   4. <root>/*/*/{...}      two levels down  (e.g. plugins/simple/env)
--   5. system python3
--
-- A venv is identified by its pyvenv.cfg, so stray directories named "env" are ignored.
local M = {}

local NAMES = { ".venv", "venv", "env", ".env" }

local function interpreter(venv_dir)
  for _, rel in ipairs({ "/bin/python", "/bin/python3", "/Scripts/python.exe" }) do
    local exe = venv_dir .. rel
    if vim.uv.fs_stat(exe) then
      return exe
    end
  end
end

local cache = {}

--- @param root string|nil project root directory
--- @return string python interpreter path
function M.interpreter(root)
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
    local exe = interpreter(vim.env.VIRTUAL_ENV)
    if exe then
      return exe
    end
  end

  root = root or vim.fn.getcwd()
  if cache[root] then
    return cache[root]
  end

  for _, prefix in ipairs({ "/", "/*/", "/*/*/" }) do
    for _, name in ipairs(NAMES) do
      -- glob() over a fixed depth is cheap; a recursive walk is not
      for _, cfg in ipairs(vim.fn.glob(root .. prefix .. name .. "/pyvenv.cfg", true, true)) do
        local exe = interpreter(vim.fs.dirname(cfg))
        if exe then
          cache[root] = exe
          return exe
        end
      end
    end
  end

  cache[root] = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3"
  return cache[root]
end

--- Forget cached lookups, for after creating a venv without restarting nvim.
function M.clear_cache()
  cache = {}
end

return M

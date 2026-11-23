local mason_path = vim.fn.stdpath("data") .. "/mason/packages"

local bundles = vim.split(
  vim.fn.glob(mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"),
  "\n", { trimempty = true }
)

require("jdtls").start_or_attach({
  cmd = {
    "java",
    "-jar", vim.fn.glob(mason_path .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration", mason_path .. "/jdtls/config_mac",
    "-data", vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t"),
  },
  root_dir = require("jdtls.setup").find_root({ "gradlew", "mvnw", ".git" }),
  init_options = { bundles = bundles },
  on_attach = function()
    require("jdtls").setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()
  end,
})

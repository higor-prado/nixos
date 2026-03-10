-- Rust IDE support via rustaceanvim.
-- Only active when rust-analyzer, cargo, and rustc are all in PATH (Nix devshell/cargo).
-- DAP: prefer codelldb (Nix wrapper) on NixOS, then fallback to lldb-dap.
return {
  {
    "mrcjkb/rustaceanvim",
    enabled = function()
      return vim.fn.executable("rust-analyzer") == 1 and vim.fn.executable("cargo") == 1 and vim.fn.executable("rustc") == 1
    end,
    config = function(_, opts)
      opts = opts or {}

      -- Prefer codelldb when available, but avoid Mason's dynamic binary on NixOS.
      local codelldb = vim.fn.exepath("codelldb")
      if codelldb ~= "" and not codelldb:find("/mason/") then
        opts.dap = {
          adapter = {
            type = "server",
            port = "${port}",
            executable = {
              command = codelldb,
              args = { "--port", "${port}" },
            },
          },
        }
      else
        local lldb_dap = vim.fn.exepath("lldb-dap")
        if lldb_dap ~= "" then
          opts.dap = {
            adapter = {
              type = "executable",
              command = lldb_dap,
              name = "lldb",
            },
          }
        end
      end

      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      local ok = pcall(require, "rustaceanvim.neotest")
      if not ok then
        opts.adapters["rustaceanvim.neotest"] = false
      end
    end,
  },
}

-- LSP configuration. All servers are Nix-managed (mason = false).
-- Mason is present but disabled for auto-install — servers come from Nix packages.
-- ts_ls is disabled in favour of vtsls for TypeScript/JavaScript.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      PATH = "append",
      ensure_installed = {},
    },
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    optional = true,
    enabled = false,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    enabled = false,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local function python_from_project()
        local cwd = vim.fn.getcwd()
        if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
          local py = vim.env.VIRTUAL_ENV .. "/bin/python"
          if vim.fn.executable(py) == 1 then
            return py
          end
        end
        for _, py in ipairs({
          cwd .. "/.venv/bin/python",
          cwd .. "/venv/bin/python",
          "python3",
          "python",
        }) do
          if vim.fn.executable(py) == 1 then
            return py
          end
        end
      end

      opts = opts or {}
      opts.setup = opts.setup or {}
      opts.servers = opts.servers or {}

      for name, server_opts in pairs(opts.servers) do
        if server_opts == true then
          opts.servers[name] = { mason = false }
        elseif type(server_opts) == "table" and server_opts.mason == nil then
          server_opts.mason = false
        end
      end

      local previous_all = opts.setup["*"]
      opts.setup["*"] = function(server, server_opts)
        if type(previous_all) == "function" and previous_all(server, server_opts) then
          return true
        end

        local cmd = server_opts and server_opts.cmd
        local bin = (type(cmd) == "table" and cmd[1]) or (type(cmd) == "string" and cmd) or nil
        if type(bin) == "string" and bin ~= "" and vim.fn.executable(bin) ~= 1 then
          return true
        end
      end

      for _, server in ipairs({ "pyright", "basedpyright" }) do
        if opts.servers[server] then
          opts.servers[server].settings = opts.servers[server].settings or {}
          opts.servers[server].settings.python = opts.servers[server].settings.python or {}
          local py = python_from_project()
          if py then
            opts.servers[server].settings.python.pythonPath = py
          end
        end
      end

      -- Prefer vtsls and keep filetypes aligned with Neovim defaults.
      opts.servers.ts_ls = opts.servers.ts_ls or {}
      opts.servers.ts_ls.enabled = false
      opts.servers.vtsls = opts.servers.vtsls or {}
      opts.servers.vtsls.enabled = true
      opts.servers.vtsls.filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }

      -- Nix language support with nil
      opts.servers["nil"] = opts.servers["nil"] or {
        mason = false,
        cmd = { "nil" },
        filetypes = { "nix" },
      }
    end,
  },
}

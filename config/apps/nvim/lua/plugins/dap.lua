-- DAP (Debug Adapter Protocol) configuration.
-- All adapters are Nix-managed — no Mason auto-installs.
-- Adapters: Python (debugpy), Lua (local-lua-debugger-vscode via node), JS/TS (pwa-node).
return {
  {
    "tomblind/local-lua-debugger-vscode",
    ft = "lua",
    build = "npm install --no-fund --no-audit && npm run build",
  },
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local dap = require("dap")
      local dapui = require("dapui")

      dap.listeners.after.event_initialized["dapui_auto_open"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_auto_open"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_auto_open"] = function()
        dapui.close()
      end

      return opts
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      local dap = require("dap")
      local js_debug = vim.fn.exepath("js-debug")
      local js_debug_adapter = vim.fn.exepath("js-debug-adapter")
      local cmd = js_debug ~= "" and js_debug or (js_debug_adapter ~= "" and js_debug_adapter or nil)
      if not cmd then
        return opts
      end

      for _, adapter_type in ipairs({ "node", "chrome", "msedge" }) do
        local pwa = "pwa-" .. adapter_type
        if type(dap.adapters[pwa]) == "table" and dap.adapters[pwa].executable then
          dap.adapters[pwa].executable.command = cmd
        end
      end

      -- Python debugging: prefer project interpreter with debugpy.
      local function first_python()
        if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
          local py = vim.env.VIRTUAL_ENV .. "/bin/python"
          if vim.fn.executable(py) == 1 then
            return py
          end
        end
        local cwd = vim.fn.getcwd()
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

      local function has_debugpy(py)
        if not py or py == "" then
          return false
        end
        vim.fn.system({ py, "-c", "import debugpy" })
        return vim.v.shell_error == 0
      end

      local py = first_python()
      if py and has_debugpy(py) then
        dap.adapters.python = {
          type = "executable",
          command = py,
          args = { "-m", "debugpy.adapter" },
        }
        dap.configurations.python = dap.configurations.python or {}
        if not vim.iter(dap.configurations.python):any(function(cfg)
          return cfg.name == "Python: current file"
        end) then
          table.insert(dap.configurations.python, {
            type = "python",
            request = "launch",
            name = "Python: current file",
            program = "${file}",
            justMyCode = false,
            console = "integratedTerminal",
          })
        end
      end

      -- Lua debugging for standalone Lua scripts.
      local lua_debugger_path = vim.fn.stdpath("data") .. "/lazy/local-lua-debugger-vscode/extension/debugAdapter.js"
      if lua_debugger_path and vim.fn.filereadable(lua_debugger_path) == 1 then
        dap.adapters["lua-local"] = {
          type = "executable",
          command = "node",
          args = { lua_debugger_path },
          enrich_config = function(config, on_config)
            if not config["extensionPath"] then
              local c = vim.deepcopy(config)
              c.extensionPath = vim.fn.stdpath("data") .. "/lazy/local-lua-debugger-vscode"
              on_config(c)
            else
              on_config(config)
            end
          end,
        }
        dap.configurations.lua = dap.configurations.lua or {}
        if not vim.iter(dap.configurations.lua):any(function(cfg)
          return cfg.name == "Lua: current file"
        end) then
          table.insert(dap.configurations.lua, {
            type = "lua-local",
            request = "launch",
            name = "Lua: current file",
            cwd = "${workspaceFolder}",
            program = {
              lua = "lua",
              file = "${file}",
            },
            args = {},
          })
        end
      end

      -- JavaScript / TypeScript launch configurations.
      for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
        dap.configurations[ft] = dap.configurations[ft] or {}
        -- Clear any existing configurations that might use ts-node
        dap.configurations[ft] = {}
        if not vim.iter(dap.configurations[ft]):any(function(cfg)
          return cfg.name == "Node: current file"
        end) then
          table.insert(dap.configurations[ft], {
            type = "pwa-node",
            request = "launch",
            name = "Node: current file",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
            -- Use Node.js built-in TypeScript support (no ts-node needed)
            runtimeExecutable = "node",
          })
        end
      end

      -- Final safety net: ensure at least one Lua config exists.
      local lua_cfg = {
        type = "lua-local",
        request = "launch",
        name = "Lua: current file",
        cwd = "${workspaceFolder}",
        program = {
          lua = "lua",
          file = "${file}",
        },
        args = {},
      }
      for _, ft in ipairs({ "lua", "luau" }) do
        dap.configurations[ft] = dap.configurations[ft] or {}
        if not vim.iter(dap.configurations[ft]):any(function(cfg)
          return cfg.name == "Lua: current file"
        end) then
          table.insert(dap.configurations[ft], vim.deepcopy(lua_cfg))
        end
      end

      return opts
    end,
  },
}

-- LSP configuration. All servers are Nix-managed.
-- Disable Mason integrations entirely so LazyVim extras do not reintroduce
-- installer state that diverges from the Nix-managed toolchain.
-- ts_ls is disabled in favour of vtsls for TypeScript/JavaScript.
return {
    {
        "mason-org/mason.nvim",
        enabled = false,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        enabled = false,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
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

            -- Nix language support with nil
            opts.servers["nil"] = opts.servers["nil"] or {
                cmd = { "nil" },
                filetypes = { "nix" },
            }

            -- Markdown: use markdown-oxide, disable marksman (injected by lang.markdown extra)
            opts.servers["marksman"] = { enabled = false }
            opts.servers["markdown_oxide"] = opts.servers["markdown_oxide"] or {
                cmd = { "markdown-oxide" },
                filetypes = { "markdown" },
            }
        end,
    },
}

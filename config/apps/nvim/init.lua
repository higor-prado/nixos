-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Track startup time
local start_time = vim.loop.hrtime()

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local end_time = vim.loop.hrtime()
    local startup_ms = (end_time - start_time) / 1000000
    vim.notify(string.format("Neovim started in %.2f ms", startup_ms))
  end,
})

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable optional providers we don't use to keep :checkhealth noise low.
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

-- Spell check: Portuguese (primary) + English (for technical terms)
vim.opt.spelllang = { "pt_br", "en" }

-- Neovim performance monitoring
return {
  -- Profile plugin load time
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    enabled = false,  -- Disable by default, enable when needed
  },

  -- Lazy.nvim profiling commands
  {
    "folke/noice.nvim",
    optional = true,
    opts = function(_, opts)
      -- Add command to profile Lazy
      vim.api.nvim_create_user_command("LazyProfile", function()
        require("lazy").stats()
        require("lazy").profile({ start = true })
        vim.notify("Profiling started... run :LazyProfile again to stop")
      end, {})
    end,
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    commit = "fd2880e8bc2c39eade94a4d329df3a14e603136d",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "bash", "regex", "rust" })
      opts.ensure_installed = vim.tbl_filter(function(lang)
        return lang ~= "jsonc"
      end, opts.ensure_installed)
      opts.auto_install = false
      opts.ignore_install = opts.ignore_install or {}
      if not vim.tbl_contains(opts.ignore_install, "jsonc") then
        table.insert(opts.ignore_install, "jsonc")
      end
    end,
  },
}

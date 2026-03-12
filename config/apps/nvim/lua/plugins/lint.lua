return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts = opts or {}
      opts.linters_by_ft = opts.linters_by_ft or {}

      -- Keep markdown readable by disabling markdownlint diagnostics from the
      -- LazyVim markdown extra while leaving the rest of the markdown stack intact.
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
    end,
  },
}

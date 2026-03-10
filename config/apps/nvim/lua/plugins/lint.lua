return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          condition = function()
            return vim.fn.executable("markdownlint-cli2") == 1
          end,
        },
      },
    },
  },
}

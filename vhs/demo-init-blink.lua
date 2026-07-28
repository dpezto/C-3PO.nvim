-- Config for the autocompletion tape, the one demo that needs a completion
-- engine. Everything else records with demo-init.lua and no dependencies.
-- Run vhs from the repo root: `vhs vhs/autocompletion.tape`.
-- blink.cmp and lazy.nvim are cloned into vhs/.deps/ on first run (gitignored),
-- so the first recording needs network and takes a while.
local root = vim.fn.getcwd()
local deps = root .. "/vhs/.deps"
local lazypath = deps .. "/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.number = false
vim.opt.laststatus = 0
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.fillchars = { eob = " " }

require("lazy").setup({
  root = deps .. "/plugins",
  lockfile = deps .. "/lazy-lock.json",
  state = deps .. "/state.json",
  install = { missing = true },
  change_detection = { enabled = false },
  spec = {
    {
      dir = root,
      name = "C-3PO.nvim",
      main = "c3po",
      opts = {
        bar_cap_start = "\u{ee03}",
        bar_char = "\u{ee04}",
        bar_cap_end = "\u{ee05}",
        bar_len = 32,
        highlighter = { auto_enable = true },
        -- latex_name resolves \textcolor{laser} against the \definecolor lines
        -- in the file, which is both what gets highlighted and what gets
        -- completed.
        pickers = { "hex", "latex_html", "latex_wave", "latex", "latex_name" },
      },
    },
    {
      "saghen/blink.cmp",
      version = "*",
      opts = {
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        completion = { menu = { auto_show = true } },
        sources = {
          -- No buffer source: it would offer the same names again, uncolored,
          -- and the demo is about the color entries.
          default = {},
          -- This is the whole integration: one provider pointing at c3po.blink.
          per_filetype = { tex = { "c3po" } },
          providers = { c3po = { name = "Color", module = "c3po.blink" } },
        },
      },
    },
  },
})

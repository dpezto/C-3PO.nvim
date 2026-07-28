-- Recording shim, loaded by every tape via
-- `nvim --cmd 'luafile vhs/demo-init.lua'`. It runs before plugins, so a config
-- spec can read the flag at startup.
--
-- There is no `-u`: your own Neovim config loads on top, which is the point --
-- the GIFs should look like the editor the plugin is actually used in, with its
-- colorscheme, its statusline and its completion engine. Recording therefore
-- needs C-3PO.nvim checked out where that config picks it up (lazy.nvim's
-- `dev`), and the recordings will differ from machine to machine.
vim.g.c3po_demo = 1

-- Recording artefacts, not preferences: a swapfile prompt or a stale mark would
-- land in the middle of a take.
vim.opt.swapfile = false
vim.opt.shadafile = "NONE"

-- Startup notifications are the one thing that reliably ruins a take: they
-- float over the buffer for seconds and say nothing about color. Silenced now,
-- and again at VimEnter for the plugins that wrap vim.notify while loading. A
-- notifier that re-wraps it later still gets through -- c3po's own "yanked ..."
-- confirmation does, and is worth keeping.
local function mute()
  vim.notify = function() end
  vim.notify_once = function() end
end
mute()
vim.api.nvim_create_autocmd("VimEnter", { callback = mute })

-- No language server has anything to add to a color demo, and their progress
-- and exit messages render on top of the text; killing a client after it
-- attached is what put ltex's shutdown warning into a take. Servers are
-- prevented from starting instead: enable() covers vim.lsp.config setups,
-- start() covers lspconfig-style ones. This shim runs before the user config,
-- so both are stubbed by the time it asks for a server.
vim.lsp.enable = function() end
vim.lsp.start = function() end

-- Recordings should not leak the time of day, and a moving statusline clock
-- makes retakes differ. Freeze os.date at 13:37, so lualine (and a clock icon
-- that picks its glyph from the hour) renders the same in every take.
local real_date, real_time = os.date, os.time
local t = real_date("*t") --[[@as osdate]]
t.hour, t.min, t.sec = 13, 37, 0
local frozen = real_time(t)
os.date = function(format, time) ---@diagnostic disable-line: duplicate-set-field
  return real_date(format, time or frozen)
end

-- Narrow blink to this plugin's source on tex. A real config wants the buffer
-- and symbol sources too, but in a recording they offer every color name a
-- second time, uncolored, next to \sansLturned.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local ok, config = pcall(require, "blink.cmp.config")
    if ok then
      config.sources.per_filetype.tex = { "c3po" }
    end
  end,
})

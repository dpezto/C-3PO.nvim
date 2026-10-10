local utils = require("c3po.utils")
local api = require("c3po.utils.api")
local picker_handler = require("c3po.handler.picker")
local hl = require("c3po.handler.highlight")

---@class c3po.Highlighter
---@field picker_ns_id integer
---@field attached_buffer table<integer, boolean> Keys are bufnrs.
---@field attachment table<integer, table> Keys are bufnrs. Identifies the live nvim_buf_attach() callbacks.
---@field stale table<integer, boolean> Keys are bufnrs. Hidden buffers to repaint once shown.
local Highlighter = {
  picker_ns_id = vim.api.nvim_create_namespace("c3po-highlighter-picker"),
  attached_buffer = {},
  attachment = {},
  stale = {},
}

function Highlighter:init()
  local opts = require("c3po.config").options
  local group = vim.api.nvim_create_augroup("c3po-highlighter", {})
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      hl.reset()
      -- Re-highlight only visible buffers. The hidden ones wait until they are
      -- shown: their marks name highlight groups the colorscheme has cleared.
      local visible_buf = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible_buf[vim.api.nvim_win_get_buf(win)] = true
      end
      for bufnr in pairs(self.attached_buffer) do
        if visible_buf[bufnr] then
          self:update(bufnr, 0, -1)
        else
          self.stale[bufnr] = true
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      if self.stale[args.buf] then
        self.stale[args.buf] = nil
        self:update(args.buf, 0, -1)
      end
    end,
  })
  -- Reloading a buffer (:edit!) detaches it, but it is still meant to be
  -- highlighted.
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(args)
      if self.attached_buffer[args.buf] and not self.attachment[args.buf] then
        self.attached_buffer[args.buf] = nil
        self:enable(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args)
      self:disable(args.buf)
    end,
  })
  if not opts.highlighter.update_insert then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      callback = function(args)
        self:update(args.buf, 0, -1)
      end,
    })
  end
end

---Return true if ft is valid.
---@param ft string
---@return boolean
local function ft_filter(ft)
  -- Disable in UI
  if ft == "c3po-ui" then
    return false
  end
  local opts = require("c3po.config").options
  if not opts.highlighter.auto_enable then
    return true
  elseif #opts.highlighter.filetypes > 0 then
    return vim.tbl_contains(opts.highlighter.filetypes, ft)
  else
    return not vim.tbl_contains(opts.highlighter.excludes, ft)
  end
end

---@param bufnr? integer
function Highlighter:enable(bufnr)
  bufnr = utils.ensure_bufnr(bufnr)
  if self.attached_buffer[bufnr] then
    return
  end
  -- filetype filter for auto_enable
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if not ft_filter(filetype) then
    return
  end
  self.attached_buffer[bufnr] = true
  self:update(bufnr, 0, -1)

  local opts = require("c3po.config").options
  -- A disable/enable cycle attaches again before the old callbacks have had a
  -- chance to detach; this tells them apart.
  local id = {}
  self.attachment[bufnr] = id
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, first_line, _, last_line)
      if self.attachment[bufnr] ~= id then
        return true
      elseif not opts.highlighter.update_insert and vim.fn.mode() == "i" then
        return
      end
      -- Without vim.schedule(), it does not update correctly when undo/redo
      vim.schedule(function()
        if self.attachment[bufnr] == id then
          self:update(bufnr, first_line, last_line)
        end
      end)
    end,
    on_detach = function()
      if self.attachment[bufnr] == id then
        self.attachment[bufnr] = nil
      end
    end,
  })
end

---@param bufnr? integer
function Highlighter:disable(bufnr)
  bufnr = utils.ensure_bufnr(bufnr)
  self.attached_buffer[bufnr] = nil
  self.attachment[bufnr] = nil
  self.stale[bufnr] = nil
  if utils.bufnr_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, self.picker_ns_id, 0, -1)
  end
end

---@param bufnr? integer
function Highlighter:toggle(bufnr)
  bufnr = utils.ensure_bufnr(bufnr)
  if self.attached_buffer[bufnr] then
    self:disable(bufnr)
  else
    self:enable(bufnr)
  end
end

---@param bufnr integer
---@param start_line integer
---@param end_line integer
function Highlighter:update(bufnr, start_line, end_line)
  if not utils.bufnr_is_valid(bufnr) then
    self:disable(bufnr)
    return
  end
  -- Scheduled repaints and autocmds may arrive after the buffer was disabled.
  if not self.attached_buffer[bufnr] then
    return
  end

  local opts = require("c3po.config").options
  local virt_pos = opts.virtual_pos == "eol" and "eol" or "inline"

  ---@param info c3po.hl_info
  ---@param ns_id integer
  local function set_hl(info, ns_id)
    if opts.highlight_mode == "virtual" then
      local r = info.range
      local pos = opts.virtual_pos == "inline-right" and { r[3], r[4] } or { r[1], r[2] }
      api.virtual_hl(bufnr, ns_id, pos, opts.virtual_symbol, virt_pos, info.hl_name)
    else
      api.set_hl(bufnr, ns_id, info.range, info.hl_name)
    end
  end

  -- LSP-sourced colors are highlighted natively by vim.lsp.document_color.
  if opts.highlighter.picker then
    local picker_info = picker_handler.info_in_range(bufnr, start_line, end_line)
    vim.api.nvim_buf_clear_namespace(bufnr, self.picker_ns_id, start_line, end_line)
    for _, info in ipairs(picker_info) do
      set_hl(info, self.picker_ns_id)
    end
  end
end

return Highlighter

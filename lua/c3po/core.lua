local utils = require("c3po.utils")
local api = require("c3po.utils.api")

---@class c3po.Core
---@field ui c3po.UI
---@field color c3po.Color
---@field prev_colors c3po.PrevColors
---@field bufnr integer Buffer the color is written back to
---@field mark_id integer Extmark spanning the text the color replaces
---@field is_insert boolean
local Core = {}
Core.__index = Core

local ns_id = vim.api.nvim_create_namespace("c3po-core-range")

---@param list { name: string }[]
---@param name string
---@return integer? #1-indexed
local function index_of(list, name)
  for i, v in ipairs(list) do
    if v.name == name then
      return i
    end
  end
end

function Core.new()
  local opts = require("c3po.config").options
  local self = setmetatable({
    ui = opts.ui.new(),
    color = require("c3po.color").new(),
    prev_colors = require("c3po.color.prev_colors").new(),
  }, Core)
  self.ui.on_quit_callback = utils.bind(self.on_quit, self)
  return self
end

--- Reset the mode of input/output, and hide alpha and prev_colors.
--- It does not initialize the color.
function Core:reset_mode()
  self.color:reset_mode()
  self.ui:reset_view()
end

---Remember where the color goes. An extmark rather than a plain range: with
---auto_close off, the buffer may be edited, or leave the window, before the
---color is completed.
---@param start_col integer 0-indexed
---@param end_col integer 0-indexed, exclusive
function Core:anchor(start_col, end_col)
  local row = api.get_cursor()
  self.bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(self.bufnr, ns_id, 0, -1)
  -- Text typed at either edge widens the range. The default gravities narrow
  -- it instead, which turns an empty range (nothing picked) inside out.
  self.mark_id = vim.api.nvim_buf_set_extmark(self.bufnr, ns_id, row, start_col, {
    end_row = row,
    end_col = end_col,
    right_gravity = false,
    end_right_gravity = true,
  })
end

function Core:pick()
  self.is_insert = false
  local opts = require("c3po.config").options
  ---@type integer?, integer?, RGB?, Alpha?, c3po.ColorInput?, c3po.ColorOutput?
  local start_col, end_col, rgb, alpha, input, output
  if opts.lsp then
    start_col, end_col, rgb, alpha = require("c3po.handler.lsp").pick()
  end
  if start_col == nil then
    start_col, end_col, rgb, alpha, input, output = require("c3po.handler.picker").pick()
  end
  -- A recognized format that is not registered falls back to the first one,
  -- as documented. Keeping the previous mode instead is not merely stale: a
  -- lingering lossy input (gray) would project the picked color onto itself.
  if input then
    self.color._input_idx = index_of(self.color._inputs, input.name) or 1
  end
  if output then
    self.color._output_idx = index_of(self.color._outputs, output.name) or 1
  end
  local _, col = api.get_cursor()
  if start_col and end_col and rgb then
    self:anchor(start_col - 1, end_col)
    self.color:set_rgb(rgb)
    -- The alpha of the previous pick must not carry over to a color without one.
    self.color.alpha:reset()
  else
    self:anchor(col, col)
    self.color:reset()
  end
  if alpha then
    self.color.alpha:set(alpha)
  end
  self.ui:open(self.color, self.prev_colors)
  self:set_color()
  -- Key mappings
  for lhs, rhs in pairs(opts.mappings) do
    vim.keymap.set("n", lhs, utils.bind(rhs, self), { nowait = true, buffer = self.ui.bufnr })
  end
end

function Core:insert()
  self.is_insert = true
  self.color:reset()
  local _, col = api.get_cursor()
  self:anchor(col, col)
  self.ui:open(self.color, self.prev_colors)
  self:set_color()
  -- Return to normal mode
  vim.cmd("stopinsert")
  -- Key mappings
  local opts = require("c3po.config").options
  for lhs, rhs in pairs(opts.mappings) do
    vim.keymap.set("n", lhs, utils.bind(rhs, self), { nowait = true, buffer = self.ui.bufnr })
  end
end

function Core:on_quit()
  local opts = require("c3po.config").options
  if opts.save_on_quit then
    self.prev_colors:prepend(self.color:copy())
  end
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_clear_namespace(self.bufnr, ns_id, 0, -1)
  end
  self:set_color("")
end

function Core:complete()
  local point = self.ui:point_at()
  if point.type == "prev" then
    -- The entry under the cursor: a click moves the cursor, not the index.
    local color = self.prev_colors:get_all()[point.index]
    if color == nil then
      return
    end
    self.color:set_rgb(color:get_rgb())
    self.ui:toggle_prev_colors(false)
    self:set_color()
    return
  end
  self.prev_colors:prepend(self.color:copy())
  self.ui.is_quit = false
  self.ui:close()
  local mark = {}
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    mark = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, ns_id, self.mark_id, { details = true })
  end
  if mark[1] then
    vim.api.nvim_buf_clear_namespace(self.bufnr, ns_id, 0, -1)
    local range = { mark[1], mark[2], mark[3].end_row, mark[3].end_col }
    if self.is_insert and vim.api.nvim_get_current_buf() == self.bufnr then
      vim.cmd("startinsert")
      api.set_cursor(range[1], range[2])
      vim.api.nvim_feedkeys(self.color:str(), "n", false)
    else
      api.set_text(self.bufnr, range, self.color:str())
    end
  end
  self:set_color("")
end

---@param color? string
function Core:set_color(color)
  color = color or self.color:hex()
  vim.g.c3po_color = color
  vim.cmd("do User C3ColorChanged")
end

return Core

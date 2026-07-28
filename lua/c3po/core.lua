local utils = require("c3po.utils")
local api = require("c3po.utils.api")

---@class c3po.Core
---@field ui c3po.UI
---@field color c3po.Color
---@field prev_colors c3po.PrevColors
---@field range integer[]
---@field is_insert boolean
local Core = {}
Core.__index = Core

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
    local index = self.color._inputs:findIndex(("x.name == %q"):format(input.name))
    self.color._input_idx = index > 0 and index or 1
  end
  if output then
    local index = self.color._outputs:findIndex(("x.name == %q"):format(output.name))
    self.color._output_idx = index > 0 and index or 1
  end
  local row, col = api.get_cursor()
  if start_col and end_col and rgb then
    self.range = { row, start_col - 1, row, end_col }
    self.color:set_rgb(rgb)
  else
    self.range = { row, col, row, col }
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
  local row, col = api.get_cursor()
  self.range = { row, col, row, col }
  self.ui:open(self.color, self.prev_colors)
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
end

function Core:complete()
  local point = self.ui:point_at()
  if point.type == "prev" then
    local color = self.prev_colors:get()
    self.color:set_rgb(color:get_rgb())
    self.ui:toggle_prev_colors(false)
    return
  end
  self.prev_colors:prepend(self.color:copy())
  self.ui.is_quit = false
  self.ui:close()
  if self.is_insert then
    vim.cmd("startinsert")
    api.set_cursor(self.range[1], self.range[2])
    vim.api.nvim_feedkeys(self.color:str(), "n", false)
  else
    api.set_text(0, self.range, self.color:str())
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

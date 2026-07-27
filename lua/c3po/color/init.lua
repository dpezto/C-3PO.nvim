local array = require("c3po.utils.array")
local hex = require("c3po.utils.hex")

---@class c3po.Color
---@field _inputs estrela.array c3po.ColorInput[]
---@field _input_idx integer
---@field _outputs estrela.array c3po.ColorOutput[]
---@field _output_idx integer
---@field alpha c3po.ColorAlpha
local Color = {}
Color.__index = Color

---@return c3po.Color
function Color.new()
  local opts = require("c3po.config").options
  local self = setmetatable({
    _inputs = array.new(),
    _input_idx = 1,
    _outputs = array.new(opts.outputs),
    _output_idx = 1,
    alpha = require("c3po.color.alpha").new(),
  }, { __index = Color })
  for _, input in ipairs(opts.inputs) do
    self._inputs:push(input:new())
  end
  local default_color = hex.parse(opts.default_color)
  self:set_rgb(default_color)
  return self
end

function Color:reset()
  local opts = require("c3po.config").options
  if opts.preserve then
    return
  end
  self._input_idx = 1
  self._output_idx = 1
  local default_color = hex.parse(opts.default_color)
  self:set_rgb(default_color)
  self.alpha:reset()
end

---@return c3po.ColorInput
function Color:input()
  return self._inputs[self._input_idx]
end

---@return c3po.ColorOutput
function Color:output()
  return self._outputs[self._output_idx]
end

---Reset input and output to default
function Color:reset_mode()
  local rgb = self:input():get_rgb()
  self._input_idx = 1
  self._output_idx = 1
  self:input():set_rgb(rgb)
end

function Color:copy()
  local new = Color.new()
  new._input_idx = self._input_idx
  new._output_idx = self._output_idx
  new:set(self:get())
  return new
end

---@param value number[]
function Color:set(value)
  self:input():set(value)
end

---@return number[] value
function Color:get()
  return self:input():get()
end

---@param RGB RGB
function Color:set_rgb(RGB)
  self:input():set_rgb(RGB)
end

---@return RGB
function Color:get_rgb()
  return self:input():get_rgb()
end

function Color:cycle_input()
  local RGB = self:input():get_rgb()
  if self._input_idx >= #self._inputs then
    self._input_idx = 1
  else
    self._input_idx = self._input_idx + 1
  end
  self:input():set_rgb(RGB)
end

function Color:cycle_output()
  if self._output_idx >= #self._outputs then
    self._output_idx = 1
  else
    self._output_idx = self._output_idx + 1
  end
end

---@return string
function Color:str()
  return self:output().str(self:input():get_rgb(), self.alpha:get())
end

---@param index? integer
---@param new_value? number
---@return string
function Color:hex(index, new_value)
  local rgb = self:get_rgb()
  if index and new_value then
    local org_color = self:get()
    self:input():callback(index, new_value)
    rgb = self:get_rgb()
    self:set(org_color)
  end
  return require("c3po.utils.hex").stringify(rgb)
end

return Color

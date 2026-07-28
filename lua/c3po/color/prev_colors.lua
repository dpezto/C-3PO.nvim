local array = require("c3po.utils.array")
local utils = require("c3po.utils")

---@class c3po.PrevColors
---@field _values estrela.array c3po.Color[]
---@field _index integer
local PrevColors = {}
PrevColors.__index = PrevColors

---@return c3po.PrevColors
function PrevColors.new()
  return setmetatable({
    _values = array.new(),
    _index = 1,
  }, PrevColors)
end

function PrevColors:reset()
  self._values = array.new()
  self._index = 1
end

---@param color c3po.Color
function PrevColors:prepend(color)
  local opts = require("c3po.config").options
  if opts.max_prev_colors < self._values:unshift(color) then
    self._values = self._values:slice(1, opts.max_prev_colors)
  end
end

---@return c3po.Color
function PrevColors:get()
  return self._values[self._index]
end

---@return c3po.Color[]
function PrevColors:get_all()
  return self._values
end

---@return integer
function PrevColors:get_index()
  return self._index
end

---@return string
function PrevColors:str()
  return self._values:map("x:hex()"):join(" ")
end

---@param d integer
function PrevColors:delta(d)
  self._index = utils.clamp(self._index + d, 1, #self._values)
end

return PrevColors

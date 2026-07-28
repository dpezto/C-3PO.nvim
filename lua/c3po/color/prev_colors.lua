local utils = require("c3po.utils")

---@class c3po.PrevColors
---@field _values c3po.Color[]
---@field _index integer
local PrevColors = {}
PrevColors.__index = PrevColors

---@return c3po.PrevColors
function PrevColors.new()
  return setmetatable({
    _values = {},
    _index = 1,
  }, PrevColors)
end

function PrevColors:reset()
  self._values = {}
  self._index = 1
end

---@param color c3po.Color
function PrevColors:prepend(color)
  local opts = require("c3po.config").options
  table.insert(self._values, 1, color)
  for i = #self._values, opts.max_prev_colors + 1, -1 do
    self._values[i] = nil
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
  local hexes = {}
  for i, color in ipairs(self._values) do
    hexes[i] = color:hex()
  end
  return table.concat(hexes, " ")
end

---@param d integer
function PrevColors:delta(d)
  self._index = utils.clamp(self._index + d, 1, #self._values)
end

return PrevColors

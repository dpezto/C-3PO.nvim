local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class LchInput: c3po.ColorInput
local LchInput = setmetatable({
  name = "LCH",
  max = { 100, 150, 360 },
  min = { 0, 0, 0 },
  delta = { 1, 1, 1 },
  bar_name = { "L", "C", "H" },
}, { __index = ColorInput })

---@param RGB RGB
---@return LCH
function LchInput.from_rgb(RGB)
  return convert.rgb2lch(RGB)
end

---@param LCH LCH
---@return RGB
function LchInput.to_rgb(LCH)
  return convert.lch2rgb(LCH)
end

return LchInput

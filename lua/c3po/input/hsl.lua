local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class HslInput: c3po.ColorInput
local HslInput = setmetatable({
  name = "HSL",
  max = { 360, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1, 0.01, 0.01 },
  bar_name = { "H", "S", "L" },
}, { __index = ColorInput })

HslInput.format = ColorInput.format_deg_percent

---@param RGB RGB
---@return HSL
function HslInput.from_rgb(RGB)
  return convert.rgb2hsl(RGB)
end

---@param HSL HSL
---@return RGB
function HslInput.to_rgb(HSL)
  return convert.hsl2rgb(HSL)
end

return HslInput

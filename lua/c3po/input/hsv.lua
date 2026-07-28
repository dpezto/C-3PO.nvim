local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class HsvInput: c3po.ColorInput
local HsvInput = setmetatable({
  name = "HSV",
  max = { 360, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1, 0.01, 0.01 },
  bar_name = { "H", "S", "V" },
}, { __index = ColorInput })

HsvInput.format = ColorInput.format_deg_percent

---@param RGB RGB
---@return HSV
function HsvInput.from_rgb(RGB)
  return convert.rgb2hsv(RGB)
end

---@param HSV HSV
---@return RGB
function HsvInput.to_rgb(HSV)
  return convert.hsv2rgb(HSV)
end

return HsvInput

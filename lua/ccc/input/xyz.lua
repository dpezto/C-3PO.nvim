local ColorInput = require("ccc.input")
local convert = require("ccc.utils.convert")

---@class XyzInput: ccc.ColorInput
local XyzInput = setmetatable({
  name = "XYZ",
  max = { 1, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 0.005, 0.005, 0.005 },
  bar_name = { "X", "Y", "Z" },
}, { __index = ColorInput })

XyzInput.format = ColorInput.format_percent

---@param RGB RGB
---@return XYZ
function XyzInput.from_rgb(RGB)
  return convert.rgb2xyz(RGB)
end

---@param XYZ XYZ
---@return RGB
function XyzInput.to_rgb(XYZ)
  return convert.xyz2rgb(XYZ)
end

return XyzInput

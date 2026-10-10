local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class XyzInput: c3po.ColorInput
local XyzInput = setmetatable({
  name = "XYZ",
  -- sRGB white, which is as far as the gamut reaches on every axis. Its Z is
  -- above 1, so a cap of 1 would tint white yellow.
  max = convert.rgb2xyz({ 1, 1, 1 }),
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

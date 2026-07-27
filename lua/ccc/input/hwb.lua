local ColorInput = require("ccc.input")
local convert = require("ccc.utils.convert")

---@class HwbInput: ccc.ColorInput
local HwbInput = setmetatable({
  name = "HWB",
  max = { 360, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1, 0.01, 0.01 },
  bar_name = { "H", "W", "B" },
}, { __index = ColorInput })

HwbInput.format = ColorInput.format_deg_percent

---@param RGB RGB
---@return HWB
function HwbInput.from_rgb(RGB)
  return convert.rgb2hwb(RGB)
end

---@param HWB HWB
---@return RGB
function HwbInput.to_rgb(HWB)
  return convert.hwb2rgb(HWB)
end

return HwbInput

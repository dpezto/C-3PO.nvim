local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class LabInput: c3po.ColorInput
local LabInput = setmetatable({
  name = "Lab",
  max = { 100, 125, 125 },
  min = { 0, -125, -125 },
  delta = { 1, 1, 1 },
  bar_name = { "L*", "a*", "b*" },
}, { __index = ColorInput })

---@param RGB RGB
---@return Lab
function LabInput.from_rgb(RGB)
  return convert.rgb2lab(RGB)
end

---@param Lab Lab
---@return RGB
function LabInput.to_rgb(Lab)
  return convert.lab2rgb(Lab)
end

return LabInput

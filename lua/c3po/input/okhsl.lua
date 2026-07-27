local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class OkhslInput: c3po.ColorInput
local OkhslInput = setmetatable({
  name = "OKHSL",
  max = { 360, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1, 0.01, 0.01 },
  bar_name = { "H", "S", "L" },
}, { __index = ColorInput })

OkhslInput.format = ColorInput.format_deg_percent

---@param RGB RGB
---@return OKHSL
function OkhslInput.from_rgb(RGB)
  return convert.rgb2okhsl(RGB)
end

---@param OKHSL OKHSL
---@return RGB
function OkhslInput.to_rgb(OKHSL)
  return convert.okhsl2rgb(OKHSL)
end

return OkhslInput

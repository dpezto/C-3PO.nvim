local ColorInput = require("c3po.input")
local convert = require("c3po.utils.convert")

---@class OkhsvInput: c3po.ColorInput
local OkhsvInput = setmetatable({
  name = "OKHSV",
  max = { 360, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1, 0.01, 0.01 },
  bar_name = { "H", "S", "V" },
}, { __index = ColorInput })

OkhsvInput.format = ColorInput.format_deg_percent

---@param RGB RGB
---@return OKHSV
function OkhsvInput.from_rgb(RGB)
  return convert.rgb2okhsv(RGB)
end

---@param OKHSV OKHSV
---@return RGB
function OkhsvInput.to_rgb(OKHSV)
  return convert.okhsv2rgb(OKHSV)
end

return OkhsvInput

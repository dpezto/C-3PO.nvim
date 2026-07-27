local ColorInput = require("c3po.input")
local utils = require("c3po.utils")

---@class RgbInput: c3po.ColorInput
local RgbInput = setmetatable({
  name = "RGB",
  max = { 1, 1, 1 },
  min = { 0, 0, 0 },
  delta = { 1 / 255, 1 / 255, 1 / 255 },
  bar_name = { "R", "G", "B" },
}, { __index = ColorInput })

---@param n number
---@return string
function RgbInput.format(n)
  n = utils.round(n * 255)
  return ("%6d"):format(n)
end

---@param RGB RGB
---@return RGB
function RgbInput.from_rgb(RGB)
  return { unpack(RGB) }
end

---@param RGB RGB
---@return RGB
function RgbInput.to_rgb(RGB)
  return { unpack(RGB) }
end

return RgbInput

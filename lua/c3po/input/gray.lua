local ColorInput = require("c3po.input")

---The first single-slider input: xcolor's gray model. Keeping a {gray} pick in
---this colorspace is what stops the sliders from wandering into colors the
---output cannot represent.
---@class GrayInput: c3po.ColorInput
local GrayInput = setmetatable({
  name = "Gray",
  max = { 1 },
  min = { 0 },
  delta = { 0.005 },
  bar_name = { "G" },
}, { __index = ColorInput })

GrayInput.format = ColorInput.format_percent

---@param RGB RGB
---@return number[]
function GrayInput.from_rgb(RGB)
  -- xcolor's rgb-to-gray conversion weights.
  return { 0.3 * RGB[1] + 0.59 * RGB[2] + 0.11 * RGB[3] }
end

---@param gray number[]
---@return RGB
function GrayInput.to_rgb(gray)
  return { gray[1], gray[1], gray[1] }
end

return GrayInput

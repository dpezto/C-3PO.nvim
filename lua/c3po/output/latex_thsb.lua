local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
local LatexThsbOutput = {
  name = "LatextHsb",
}

function LatexThsbOutput.str(RGB)
  -- xcolor's tHsb model is Hsb with the hue pushed through the inverse of the
  -- tuning polyline.
  local H, S, B = unpack(convert.rgb2hsv(RGB))
  return ("{tHsb}{%.1f, %.3f, %.3f}"):format(convert.hsb2thsb_hue(H), S, B)
end

return LatexThsbOutput

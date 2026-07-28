local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
local LatexHsb360Output = {
  name = "LatexHsb",
}

function LatexHsb360Output.str(RGB)
  -- xcolor's Hsb model is hsb with the hue in degrees.
  local H, S, B = unpack(convert.rgb2hsv(RGB))
  return ("{Hsb}{%.1f, %.3f, %.3f}"):format(H, S, B)
end

return LatexHsb360Output

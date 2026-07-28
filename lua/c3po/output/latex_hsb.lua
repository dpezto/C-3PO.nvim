local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "Latexhsb",
  str = function(RGB)
    -- xcolor's hsb model takes three values in [0,1], the hue included.
    local H, S, B = unpack(convert.rgb2hsv(RGB))
    return ("{hsb}{%.3f, %.3f, %.3f}"):format(H / 360, S, B)
  end,
}

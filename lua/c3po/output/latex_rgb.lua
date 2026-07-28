local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "LatexRGB",
  str = function(RGB)
    local R, G, B = convert.rgb_format(RGB)
    return ("{RGB}{%d, %d, %d}"):format(R, G, B)
  end,
}

local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "LatexCMYK",
  str = function(RGB)
    -- xcolor's cmyk model takes four values in [0,1].
    local C, M, Y, K = unpack(convert.rgb2cmyk(RGB))
    return ("{cmyk}{%.3f, %.3f, %.3f, %.3f}"):format(C, M, Y, K)
  end,
}

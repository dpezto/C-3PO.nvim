local convert = require("ccc.utils.convert")

---@class ccc.ColorOutput
local LatexCmykOutput = {
  name = "LatexCMYK",
}

function LatexCmykOutput.str(RGB)
  -- xcolor's cmyk model takes four values in [0,1].
  local C, M, Y, K = unpack(convert.rgb2cmyk(RGB))
  return ("{cmyk}{%.3f, %.3f, %.3f, %.3f}"):format(C, M, Y, K)
end

return LatexCmykOutput

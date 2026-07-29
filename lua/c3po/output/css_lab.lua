local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssLab",
  str = function(RGB, A)
    local L, a, b = unpack(convert.rgb2lab(RGB))
    L = utils.fmt(L, 2)
    a = utils.fmt(a, 2)
    b = utils.fmt(b, 2)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("lab(%s%% %s %s / %s%%)"):format(L, a, b, A)
    else
      return ("lab(%s%% %s %s)"):format(L, a, b)
    end
  end,
}

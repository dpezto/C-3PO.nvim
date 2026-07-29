local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssLCH",
  str = function(RGB, A)
    local L, C, H = unpack(convert.rgb2lch(RGB))
    L = utils.fmt(L, 2)
    C = utils.fmt(C, 2)
    H = utils.fmt(H, 2)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("lch(%s%% %s %s / %s%%)"):format(L, C, H, A)
    else
      return ("lch(%s%% %s %s)"):format(L, C, H)
    end
  end,
}

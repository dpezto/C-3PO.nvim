local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssLCH",
  str = function(RGB, A)
    local L, C, H = unpack(convert.rgb2lch(RGB))
    L = utils.round(L)
    C = utils.round(C)
    H = utils.round(H)
    if A then
      A = utils.round(A * 100)
      return ("lch(%d%% %d %d / %d%%)"):format(L, C, H, A)
    else
      return ("lch(%d%% %d %d)"):format(L, C, H)
    end
  end,
}

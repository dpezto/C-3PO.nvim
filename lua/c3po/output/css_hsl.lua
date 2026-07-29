local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssHSL",
  str = function(RGB, A)
    local H, S, L = unpack(convert.rgb2hsl(RGB))
    H = utils.fmt(H, 2)
    S = utils.fmt(S * 100, 2)
    L = utils.fmt(L * 100, 2)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("hsl(%s %s%% %s%% / %s%%)"):format(H, S, L, A)
    else
      return ("hsl(%s %s%% %s%%)"):format(H, S, L)
    end
  end,
}

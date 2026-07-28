local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssHSL",
  str = function(RGB, A)
    local H, S, L = unpack(convert.rgb2hsl(RGB))
    H = utils.round(H)
    S = utils.round(S * 100)
    L = utils.round(L * 100)
    if A then
      A = utils.round(A * 100)
      return ("hsl(%d %d%% %d%% / %d%%)"):format(H, S, L, A)
    else
      return ("hsl(%d %d%% %d%%)"):format(H, S, L)
    end
  end,
}

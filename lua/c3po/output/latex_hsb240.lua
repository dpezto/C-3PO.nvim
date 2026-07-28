local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "LatexHSB",
  str = function(RGB)
    -- xcolor's HSB model scales all three components to [0, 240], hue included.
    local H, S, B = unpack(convert.rgb2hsv(RGB))
    return ("{HSB}{%d, %d, %d}"):format(utils.round(H / 360 * 240), utils.round(S * 240), utils.round(B * 240))
  end,
}

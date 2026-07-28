local utils = require("c3po.utils")

---@class c3po.ColorOutput
return {
  name = "LatexGray",
  str = function(RGB)
    -- xcolor's rgb-to-gray conversion weights, scaled to Gray's [0, 15] integers.
    local gray = 0.3 * RGB[1] + 0.59 * RGB[2] + 0.11 * RGB[3]
    return ("{Gray}{%d}"):format(utils.round(gray * 15))
  end,
}

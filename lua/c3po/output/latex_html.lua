local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
local LatexHtmlOutput = {
  name = "LatexHTML",
}

function LatexHtmlOutput.str(RGB)
  -- xcolor's HTML model takes exactly six hex digits, without a leading `#`.
  local R, G, B = convert.rgb_format(RGB)
  return ("{HTML}{%02X%02X%02X}"):format(R, G, B)
end

return LatexHtmlOutput

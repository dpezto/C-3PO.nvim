---@class c3po.ColorOutput
local LatexGrayOutput = {
  name = "Latexgray",
}

function LatexGrayOutput.str(RGB)
  -- xcolor's rgb-to-gray conversion weights (xcolor manual, color conversion).
  local gray = 0.3 * RGB[1] + 0.59 * RGB[2] + 0.11 * RGB[3]
  return ("{gray}{%.3f}"):format(gray)
end

return LatexGrayOutput

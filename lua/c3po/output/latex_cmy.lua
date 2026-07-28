---@class c3po.ColorOutput
local LatexCmyOutput = {
  name = "LatexCMY",
}

function LatexCmyOutput.str(RGB)
  return ("{cmy}{%.3f, %.3f, %.3f}"):format(1 - RGB[1], 1 - RGB[2], 1 - RGB[3])
end

return LatexCmyOutput

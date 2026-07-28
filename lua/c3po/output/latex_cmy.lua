---@class c3po.ColorOutput
return {
  name = "LatexCMY",
  str = function(RGB)
    return ("{cmy}{%.3f, %.3f, %.3f}"):format(1 - RGB[1], 1 - RGB[2], 1 - RGB[3])
  end,
}

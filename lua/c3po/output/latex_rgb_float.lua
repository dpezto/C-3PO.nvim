---@class c3po.ColorOutput
return {
  name = "Latexrgb",
  str = function(RGB)
    -- xcolor's rgb model takes three values in [0,1].
    return ("{rgb}{%.3f, %.3f, %.3f}"):format(RGB[1], RGB[2], RGB[3])
  end,
}

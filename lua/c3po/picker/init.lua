local pattern = require("c3po.utils.pattern")

---Build a picker from vim regex patterns and a capture translator.
---The scan loop is shared by every literal picker: find the earliest match,
---let `to_rgb` validate and convert the captures, and when it rejects them
---advance past the match so the rest of the line is still searched.
---@param spec { patterns: string[], min_len: integer, to_rgb: fun(...: string?): (RGB?, Alpha?) }
---@return c3po.ColorPicker
return function(spec)
  local Picker = { pattern = spec.patterns }

  ---@param s string
  ---@param init? integer
  ---@return integer? start_col
  ---@return integer? end_col
  ---@return RGB? rgb
  ---@return Alpha? alpha
  function Picker:parse_color(s, init)
    init = init or 1
    while init <= #s - (spec.min_len - 1) do
      local start_col, end_col, c1, c2, c3, c4 = pattern.find_first(s, self.pattern, init)
      if not (start_col and end_col and c1 and c2 and c3) then
        return
      end
      local RGB, A = spec.to_rgb(c1, c2, c3, c4)
      if RGB then
        return start_col, end_col, RGB, A
      end
      init = end_col + 1
    end
  end

  return Picker
end

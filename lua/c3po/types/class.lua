---@class c3po.UI
---@field bufnr integer
---@field winid integer
---@field ns_id integer
---@field color c3po.Color
---@field show_prev_colors boolean
---@field before_color c3po.Color
---@field prev_colors c3po.PrevColors
---@field is_quit boolean
---@field on_quit_callback? function
---@field new fun(): c3po.UI
---@field open fun(self: c3po.UI, color: c3po.Color, prev_colors: c3po.PrevColors)
---@field update fun(self: c3po.UI)
---@field close fun(self: c3po.UI)
---@field on_close fun(self: c3po.UI)
---@field reset_view fun(self: c3po.UI)
---@field point_at fun(self: c3po.UI): c3po.UI.point
---@field set_point fun(self: c3po.UI, point: c3po.UI.point)

---@class c3po.UI.point
---@field type "none" | "color" | "alpha" | "prev"
---@field index integer

---@class c3po.ColorInput
---@field name string
---@field value number[]
---@field max number[]
---@field min number[]
---@field delta number[] #Minimum slider movement.
---@field bar_name string[] #Align all display widths.
---@field format fun(n: number, i: integer): string #String returned must be 6 byte.
---@field from_rgb fun(RGB: RGB): value: number[]
---@field to_rgb fun(value: number[]): RGB
---@field callback fun(self: c3po.ColorInput, new_value: number, index: integer)

---@class c3po.ColorOutput
---@field name string
---@field str fun(RGB: number[], A?: number): string

---@class c3po.ColorPicker
---@field parse_color fun(self, s: string, init?: integer, bufnr?: integer): start: integer?, end_: integer?, RGB: RGB?, Alpha: Alpha?, hl_def: vim.api.keyset.highlight?

---@alias c3po.Position integer[] { row, col } 0-indexed
---@alias c3po.Range integer[] { start_row, start_col, end_row, end_col } 0-indexed, Only end_col is exclusive

---@class c3po.hl_info
---@field range c3po.Range
---@field hl_name string

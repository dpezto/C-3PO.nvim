local M = {}

---@type ccc.Options
---@diagnostic disable-next-line
M.options = {}

---Resolve a module name to the module itself.
---Anything that is not a string is already a module and passes through, so a
---list may mix names with modules built at runtime (custom_entries and friends
---are constructors, and have no name to resolve).
---@param kind "input"|"output"|"picker"
---@param value string|table
---@param where string #Option name, for the error message
---@return table? #nil when the name does not resolve
local function resolve(kind, value, where)
  if type(value) ~= "string" then
    return value
  end
  local ok, mod = pcall(require, ("ccc.%s.%s"):format(kind, value))
  if not ok or type(mod) ~= "table" then
    vim.notify(("[ccc] %s: no such %s: %q"):format(where, kind, value), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

---@param kind "input"|"output"|"picker"
---@param list (string|table)[]
---@param where string
---@return table[]
local function resolve_list(kind, list, where)
  local resolved = {}
  for _, value in ipairs(list) do
    local mod = resolve(kind, value, where)
    if mod then
      resolved[#resolved + 1] = mod
    end
  end
  return resolved
end

---`convert` takes either explicit {picker, output} pairs or, when its entries
---are names, a cycle: each format converts to the next and the last back to
---the first. The cycle form needs names because it looks each one up as both a
---picker and an output.
---@param convert (string|table)[]
---@return { [1]: ccc.ColorPicker, [2]: ccc.ColorOutput }[]
local function resolve_convert(convert)
  local resolved = {}
  if type(convert[1]) ~= "string" then
    for _, pair in ipairs(convert) do
      local picker = resolve("picker", pair[1], "convert")
      local output = resolve("output", pair[2], "convert")
      if picker and output then
        resolved[#resolved + 1] = { picker, output }
      end
    end
    return resolved
  end
  for i, name in ipairs(convert) do
    local picker = resolve("picker", name, "convert")
    local output = resolve("output", convert[i % #convert + 1], "convert")
    if picker and output then
      resolved[#resolved + 1] = { picker, output }
    end
  end
  return resolved
end

---@param pattern table<string|table, (string|table)[]>
---@return table<ccc.ColorPicker, { [1]: ccc.ColorInput, [2]: ccc.ColorOutput }>
local function resolve_recognize(pattern)
  local resolved = {}
  for key, value in pairs(pattern) do
    local picker = resolve("picker", key, "recognize.pattern")
    if picker then
      resolved[picker] =
        { resolve("input", value[1], "recognize.pattern"), resolve("output", value[2], "recognize.pattern") }
    end
  end
  return resolved
end

---@param opts ccc.Options.P
function M.setup(opts)
  -- Merge user options to default one.
  local default = require("ccc.config.default")
  if opts.disable_default_mappings then
    default = vim.tbl_extend("force", {}, default, { mappings = {} })
  end
  M.options = vim.tbl_deep_extend("force", {}, default, M.options, opts)
  for lhs, rhs in pairs(M.options.mappings) do
    if rhs == require("ccc.mapping").none then
      M.options.mappings[lhs] = nil
    end
  end

  -- Names are accepted anywhere a module is, so that configuring these does not
  -- require pulling ccc.input/output/picker into scope first.
  M.options.inputs = resolve_list("input", M.options.inputs, "inputs")
  M.options.outputs = resolve_list("output", M.options.outputs, "outputs")
  M.options.pickers = resolve_list("picker", M.options.pickers, "pickers")
  M.options.convert = resolve_convert(M.options.convert)
  M.options.recognize.pattern = resolve_recognize(M.options.recognize.pattern)
end

return M

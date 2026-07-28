local hl = require("c3po.handler.highlight")
local latex = require("c3po.picker.latex")
local utils = require("c3po.utils")
local pattern = require("c3po.utils.pattern")

---xcolor colors used by name. `\definecolor{R2D2}{RGB}{0, 112, 192}` sits in
---the preamble, `\textcolor{R2D2}{...}` in a chapter file, so resolving a name
---means looking beyond the current buffer.
---@class c3po.ColorPicker.LatexName: c3po.ColorPicker
---@field patterns string[]
local LatexNamePicker = {}

-- The span is a name, not a color literal: overwriting it with `#0070c0` would
-- throw away the indirection the document is built on. `:C3 pick` skips it.
LatexNamePicker.readonly = true

local TEX_FT = { tex = true, latex = true, plaintex = true }

-- A color name is what xcolor lets you write between the braces. `!` is excluded
-- on purpose: it opens a mixing expression (`R2D2!50!white`).
local NAME = [=[[0-9A-Za-z@_-]+]=]
-- \definecolor's optional [type] argument, and \color's optional [model] one.
local OPT = [=[%(\[[^]]*\])?]=]

-- \C: names are case-sensitive, so 'ignorecase' must never merge R2D2 with
-- r2d2. \zs and \ze are what make the reported span the bare name, which is
-- also what keeps the definition's `{RGB}{...}` visible to the latex picker: the
-- handler resumes at the end of the name, not at the end of the command.
local DEFINITION = [=[\C\v\\%(define|provide)color]=] .. OPT .. [=[\{\zs]=] .. NAME .. [=[\ze\}]=]

---@return string[]
local function build_patterns()
  return {
    DEFINITION,
    -- Every command that takes a color name as its first braced argument. No
    -- optional-argument group here: `\color[RGB]{0,112,192}` is a specification,
    -- not a name, and belongs to the latex picker.
    [=[\C\v\\%(text|page|f|cell|row|column)?color%(box)?\*?\{\zs]=] .. NAME .. [=[\ze[}!]]=],
    -- \colorlet{new}{old}: `old` is the one we can resolve. `new` is deliberately
    -- left alone -- see the ponytail note on mixing expressions below.
    [=[\C\v\\colorlet]=] .. OPT .. [=[\{]=] .. NAME .. [=[\}\{\zs]=] .. NAME .. [=[\ze[}!]]=],
  }
end

-- xcolor's base names, always available without a package option. Kept under the
-- project's own definitions so that `\definecolor{red}{...}` wins.
---@type table<string, RGB>
local BUILTIN = {
  black = { 0, 0, 0 },
  blue = { 0, 0, 1 },
  brown = { 0.75, 0.5, 0.25 },
  cyan = { 0, 1, 1 },
  darkgray = { 0.25, 0.25, 0.25 },
  gray = { 0.5, 0.5, 0.5 },
  green = { 0, 1, 0 },
  lightgray = { 0.75, 0.75, 0.75 },
  lime = { 0.75, 1, 0 },
  magenta = { 1, 0, 1 },
  olive = { 0.5, 0.5, 0 },
  orange = { 1, 0.5, 0 },
  pink = { 1, 0.75, 0.75 },
  purple = { 0.75, 0, 0.25 },
  red = { 1, 0, 0 },
  teal = { 0, 0.5, 0.5 },
  violet = { 0.5, 0, 0.5 },
  white = { 1, 1, 1 },
  yellow = { 1, 1, 0 },
}

---Collect every `\definecolor` / `\providecolor` these lines resolve.
---Pure: no filesystem, no buffer, so it is the seam the tests drive.
---@param lines string[]
---@return table<string, RGB>
function LatexNamePicker.scan_lines(lines)
  local names = {}
  for _, line in ipairs(lines) do
    local init = 1
    while init <= #line do
      local start_col, end_col = pattern.find(line, DEFINITION, init)
      if start_col == nil or end_col == nil then
        break
      end
      -- The value follows the closing brace of the name.
      local gap = line:match("^}(%s*)", end_col + 1)
      if gap then
        local spec_init = end_col + 2 + #gap
        local spec_col, _, rgb = latex:parse_color(line, spec_init)
        -- Anchored: a model this plugin does not resolve ({named}) must not
        -- borrow the specification of a later definition on the same line.
        if rgb and spec_col == spec_init then
          names[line:sub(start_col, end_col)] = rgb
        end
      end
      init = end_col + 1
    end
  end
  return names
end

---@type table<string, table<string, RGB>> #Keyed by project root
local project = {}
---@type table<integer, table<string, RGB>> #Keyed by bufnr, only while modified
local live = {}
---@type table<integer, integer> #The changedtick each live entry was built from
local live_tick = {}
---@type table<integer, string>
local roots = {}

-- texlab's own root markers, plus .git for everyone who has none of them.
local MARKERS = { ".latexmkrc", "latexmkrc", "Tectonic.toml", ".texlabroot", "texlabroot", ".git" }

---@param bufnr integer
---@return string #Empty when the buffer has no file to anchor on
local function root_of(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return ""
  end
  -- Never fall back to $HOME: the scan below would walk the whole home directory.
  return vim.fs.root(bufnr, MARKERS) or vim.fs.dirname(name) or ""
end

---@param root string
---@return table<string, RGB>
local function scan_project(root)
  local names = {}
  if root == "" then
    return names
  end
  -- ponytail: every *.tex/*.sty under the project root, capped at 200 files.
  -- Following \input/\include properly needs TEXINPUTS, extension inference,
  -- \subimport bases and root-document detection -- texlab keeps a whole
  -- Workspace type for it. The glob is a superset for the price of some
  -- unrelated names, and a stray name is a stray swatch, not a wrong color.
  local files = vim.fs.find(function(name)
    return name:match("%.tex$") ~= nil or name:match("%.sty$") ~= nil
  end, { path = root, type = "file", limit = 200 })
  for _, path in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok then
      names = vim.tbl_extend("force", names, LatexNamePicker.scan_lines(lines))
    end
  end
  return names
end

---Every color name visible from this buffer: builtins, then the project's
---definitions, then the unsaved ones in the buffer itself.
---@param bufnr integer
---@return table<string, RGB>
function LatexNamePicker.names(bufnr)
  local root = roots[bufnr]
  if root == nil then
    root = root_of(bufnr)
    roots[bufnr] = root
  end

  local base = project[root]
  if base == nil then
    base = vim.tbl_extend("force", BUILTIN, scan_project(root))
    project[root] = base
  end

  -- The buffer is scanned whether or not it is modified: it may be a scratch
  -- buffer, or sit outside the project root, or fall past the file cap, and in
  -- every one of those cases the project scan has not seen it. The tick guard
  -- makes the unmodified case a one-off.
  -- ponytail: one full-buffer rescan per change, not per repaint -- the
  -- changedtick guard collapses the several parse_color calls one keystroke makes
  -- into a single scan. A few thousand lines is a few milliseconds; if that ever
  -- bites, narrow the rescan to the range on_lines already hands the highlighter.
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  if live_tick[bufnr] ~= tick then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local merged = vim.tbl_extend("force", base, LatexNamePicker.scan_lines(lines))
    -- A definition changed, so every use of that name is the wrong color now --
    -- including the ones this repaint will not reach, since on_lines only covers
    -- the edited range. Scheduled because we are inside that very repaint.
    if not vim.deep_equal(live[bufnr] or base, merged) then
      vim.schedule(function()
        require("c3po.highlighter"):update(bufnr, 0, -1)
      end)
    end
    live[bufnr], live_tick[bufnr] = merged, tick
  end
  return live[bufnr]
end

function LatexNamePicker:init()
  if self.patterns then
    return
  end
  self.patterns = build_patterns()

  -- Within a buffer the changedtick guard in names() keeps everything current.
  -- A write is the one event that changes what *other* buffers can see, since
  -- the project scan reads files rather than buffers.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("c3po-latex-name", {}),
    pattern = { "*.tex", "*.sty" },
    callback = function()
      project, live, live_tick, roots = {}, {}, {}, {}
      local highlighter = require("c3po.highlighter")
      for bufnr in pairs(highlighter.attached_buffer) do
        if vim.api.nvim_buf_is_valid(bufnr) and TEX_FT[vim.bo[bufnr].filetype] then
          highlighter:update(bufnr, 0, -1)
        end
      end
    end,
  })
end

---@param s string
---@param init? integer
---@param bufnr? integer
---@return integer? start_col 1-indexed
---@return integer? end_col 1-indexed, inclusive
---@return RGB?
function LatexNamePicker:parse_color(s, init, bufnr)
  self:init()
  bufnr = utils.ensure_bufnr(bufnr)
  if not TEX_FT[vim.bo[bufnr].filetype] then
    return
  end
  local names = self.names(bufnr)
  init = init or 1
  while init <= #s do
    local start_col, end_col = pattern.find_first(s, self.patterns, init)
    if start_col == nil or end_col == nil then
      return
    end
    local rgb = names[s:sub(start_col, end_col)]
    if rgb then
      return start_col, end_col, rgb
    end
    -- An unknown name is not a reason to abandon the rest of the line.
    init = end_col + 1
  end
end

--{{{ Completion
-- Which side answered the current completion round, per buffer. The protocol
-- calls the function twice and derives `base` from the first call's column, so
-- the second call must not decide again.
---@type table<integer, boolean>
local delegating = {}
---@type table<integer, string>
local previous = {}

---@param bufnr integer
---@param findstart 0|1
---@param base string
---@return integer|table[]
local function delegate(bufnr, findstart, base)
  local prev = previous[bufnr]
  -- ponytail: vim.fn[...] calls a Vimscript function name, which covers the
  -- realistic conflict (vimtex#complete#omnifunc). A `v:lua.` valued omnifunc
  -- is left alone rather than guessed at.
  if prev and prev ~= "" and not prev:match("^v:lua%.") then
    local ok, result = pcall(vim.fn[prev], findstart, base)
    if ok then
      return result
    end
  end
  -- -2 cancels silently and leaves the buffer untouched.
  return findstart == 1 and -2 or {}
end

---The byte offset where the color name under the cursor starts, or nil when the
---cursor is not inside a color command's braced argument. Shared by every
---completion front end, so they all agree on where a name begins.
---@param line string
---@param col integer #0-based byte offset of the cursor
---@return integer? #0-based
function LatexNamePicker.arg_start(line, col)
  local before = line:sub(1, col)
  local start = before:find("[0-9A-Za-z@_-]*$")
  if start == nil then
    return
  end
  local prefix = before:sub(1, start - 1)
  if prefix:match("\\%a*color%a*{$") or prefix:match("\\colorlet{[0-9A-Za-z@_-]+}{$") then
    return start - 1
  end
end

---@param rgb RGB
---@return string
function LatexNamePicker.hex(rgb)
  return ("#%02x%02x%02x"):format(utils.round(rgb[1] * 255), utils.round(rgb[2] * 255), utils.round(rgb[3] * 255))
end

---A highlight group drawing the color itself, for a completion entry to wear.
---Foreground rather than background: the entry gets a tinted glyph, not a block
---that fights the menu's own selection highlight.
---@param bufnr integer
---@param rgb RGB
---@return string? #nil while the highlighter is not attached to this buffer
function LatexNamePicker.swatch_hl(bufnr, rgb)
  if not require("c3po.highlighter").attached_buffer[bufnr] then
    return
  end
  return hl.ensure_hl_name(nil, { fg = LatexNamePicker.hex(rgb) })
end

---@param bufnr integer
---@return integer?
local function color_arg_start(bufnr)
  if not TEX_FT[vim.bo[bufnr].filetype] then
    return
  end
  return LatexNamePicker.arg_start(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2])
end

---Standard 'omnifunc'/'completefunc' protocol. Outside a color argument it hands
---the round to whatever function it replaced, so vimtex keeps its own completion.
---@param findstart 0|1
---@param base string
---@return integer|table[]
function LatexNamePicker.omnifunc(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()
  if findstart == 1 then
    local start = color_arg_start(bufnr)
    delegating[bufnr] = start == nil
    if start then
      return start
    end
  end
  if delegating[bufnr] then
    return delegate(bufnr, findstart, base)
  end

  local items = {}
  for name, rgb in pairs(LatexNamePicker.names(bufnr)) do
    if vim.startswith(name:lower(), base:lower()) then
      table.insert(items, {
        word = name,
        kind = "Color",
        menu = LatexNamePicker.hex(rgb),
        kind_hlgroup = LatexNamePicker.swatch_hl(bufnr, rgb),
      })
    end
  end
  table.sort(items, function(a, b)
    return a.word < b.word
  end)
  return items
end

---@param bufnr integer
local function install(bufnr)
  -- Deferred because vimtex sets 'omnifunc' from its own ftplugin, on the very
  -- event that gets us here: scheduling is what guarantees we capture it
  -- instead of racing it up the runtimepath.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local current = vim.bo[bufnr].omnifunc
    if current:match("latex_name") then
      return
    end
    previous[bufnr] = current
    vim.bo[bufnr].omnifunc = "v:lua.require'c3po.picker.latex_name'.omnifunc"
  end)
end

---Install the completion function on tex buffers, keeping whatever was there.
function LatexNamePicker.setup_completion()
  -- Completing without highlighting is a valid setup, and it still needs the
  -- cache invalidated; parse_color would otherwise be the only thing that ever
  -- calls init().
  LatexNamePicker:init()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("c3po-latex-completion", {}),
    pattern = { "tex", "latex", "plaintex" },
    callback = function(ev)
      install(ev.buf)
    end,
  })
  -- Under a lazy-loading plugin manager setup() itself often runs *from* the
  -- FileType event of the buffer that triggered the load, and an autocmd
  -- created during an event never fires for that same event.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and TEX_FT[vim.bo[bufnr].filetype] then
      install(bufnr)
    end
  end
end
-- }}}

return LatexNamePicker

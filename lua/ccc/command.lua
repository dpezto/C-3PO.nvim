---@class ccc.CommandConfig
---@field nargs string|integer #Same meaning as :command-nargs, checked per call
---@field desc string
---@field complete? fun(arg_lead: string, cmdline: string, cursor_pos: integer): string[]
---@field func fun(core: ccc.Core, data: table)
---@field name? string

---@class ccc.CommandModule
---@field commands table<string, ccc.CommandConfig>
local M = { commands = {} }

---@param name string
---@param config ccc.CommandConfig
function M.register(name, config)
  config.name = name
  M.commands[name] = config
end

---@return string[]
local function names()
  local list = vim.tbl_keys(M.commands)
  table.sort(list)
  return list
end

---@param prefix string
---@param candidates string[]
---@return string[]
local function starting_with(prefix, candidates)
  return vim.tbl_filter(function(s)
    return vim.startswith(s, prefix)
  end, candidates)
end

---@param bufnr? string
---@return integer?
local function to_bufnr(bufnr)
  return bufnr and tonumber(bufnr) or nil
end

M.register("pick", {
  nargs = 0,
  desc = "Detect and replace the color under the cursor",
  func = function(core)
    core:pick()
  end,
})

M.register("convert", {
  nargs = 0,
  desc = "Convert the color under the cursor without opening the UI",
  func = function()
    require("ccc.convert").toggle()
  end,
})

local highlighter_actions = { "enable", "disable", "toggle" }

M.register("highlighter", {
  nargs = "+",
  desc = "Enable, disable or toggle highlighting in a buffer",
  complete = function(arg_lead, cmdline)
    -- Only the action completes; the optional {bufnr} that may follow it has
    -- no useful candidate list.
    if cmdline:match("^%s*Ccc%s+highlighter%s+%S*$") then
      return starting_with(arg_lead, highlighter_actions)
    end
    return {}
  end,
  func = function(_, data)
    local action, bufnr = data.fargs[1], data.fargs[2]
    if not vim.tbl_contains(highlighter_actions, action) then
      vim.notify(
        ("[ccc] highlighter: expected %s, got %q"):format(table.concat(highlighter_actions, "/"), action or ""),
        vim.log.levels.ERROR
      )
      return
    end
    require("ccc.highlighter")[action](require("ccc.highlighter"), to_bufnr(bufnr))
  end,
})

---@param nargs string|integer
---@param given integer
---@return boolean
local function nargs_ok(nargs, given)
  if nargs == "*" then
    return true
  elseif nargs == "?" then
    return given <= 1
  elseif nargs == "+" then
    return given >= 1
  end
  return nargs == given
end

---@param core ccc.Core
local function show_menu(core)
  local choices = names()
  vim.ui.select(choices, {
    prompt = "Ccc",
    format_item = function(name)
      return ("%-12s %s"):format(name, M.commands[name].desc)
    end,
  }, function(name)
    if name == nil then
      return
    end
    -- Subcommands that need arguments cannot be run straight from the menu.
    if not nargs_ok(M.commands[name].nargs, 0) then
      vim.api.nvim_feedkeys((":Ccc %s "):format(name), "n", false)
      return
    end
    M.commands[name].func(core, { fargs = {} })
  end)
end

---@param core ccc.Core
---@param data table
function M.handle(core, data)
  local name = table.remove(data.fargs, 1)
  local config = M.commands[name]
  if config == nil then
    vim.notify(("[ccc] unknown subcommand: %s"):format(name), vim.log.levels.ERROR)
    return
  end
  if not nargs_ok(config.nargs, #data.fargs) then
    vim.notify(
      ("[ccc] %s: expected %s arguments, got %d"):format(name, config.nargs, #data.fargs),
      vim.log.levels.ERROR
    )
    return
  end
  config.func(core, data)
end

---@param arg_lead string
---@param cmdline string
---@param cursor_pos integer
---@return string[]
function M.complete(arg_lead, cmdline, cursor_pos)
  local subcommand = cmdline:match("^%s*Ccc%s+(%S+)%s")
  if subcommand == nil then
    return starting_with(arg_lead, names())
  end
  local config = M.commands[subcommand]
  if config == nil or config.complete == nil then
    return {}
  end
  return config.complete(arg_lead, cmdline, cursor_pos)
end

---@param core ccc.Core
function M.create(core)
  vim.api.nvim_create_user_command("Ccc", function(data)
    if #data.fargs == 0 then
      show_menu(core)
      return
    end
    M.handle(core, data)
  end, {
    nargs = "*",
    desc = "ccc.nvim",
    complete = M.complete,
  })
end

return M

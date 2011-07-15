#!/usr/bin/env luajit

--[[ Ophal v0.1-alpha3 ]]

print [[Content-type: text/html; charset=utf-8
]]

function include(file)
  file = table.concat({[[themes]], settings.slash, settings.theme, settings.slash, file, [[.tpl.html]]}) 
  local attr, err = lfs.attributes(file)
  
  if attr ~= nil and attr.mode == [[file]] then
    -- read file contents
    local fh = assert(io.open(file))
    local src = 'print [[' .. fh:read([[*a]]) .. ']]'
    fh:close()

    -- load source code
    local prog, err = loadstring(src)
    if not prog then
      error(file .. [[: ]] .. err)
    end
    setfenv(prog, env)

    -- execute
    local status, err = pcall(prog)
    if not status then
      error(err)
    end
  else
    error(err)
  end
end

-- Allowed functions and Lua modules
env = {io = {open = io.open, stderr = io.stderr}, pcall = pcall, loadstring = loadstring, setfenv = setfenv, assert = assert, print = function (s) io.write(s); end, echo = function (...) for _, v in pairs({...}) do io.write(v); end end, table = table, require = require, error = error, lfs = require [[lfs]], include = include, settings = require [[settings]]}
env.env = env

setfenv(include, env)

include([[html]])

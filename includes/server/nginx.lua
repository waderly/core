local seawolf = require 'seawolf'.__build('text')
local time, ngx_print, ngx_var, ngx_req = os.time, ngx.print, ngx.var, ngx.req
local explode, unescape = seawolf.text.explode, socket.url.unescape
local trim = seawolf.text.trim

env._SERVER = function (v)
  if v == 'QUERY_STRING' then
    return ngx_var.args
  elseif v == 'SCRIPT_NAME' then
    return ngx_var.uri
  elseif v == 'HTTP_HOST' then
    return ngx_req.get_headers()["Host"]
  elseif v == 'SERVER_NAME' then
    return ngx_var[v:lower()]
  else
    return ngx_var[v]
  end
end

local cookies, parsed, tmp, key, value = ngx_req.get_headers()['Cookie'] or '', {}
cookies = explode(';', cookies)
for _, v in pairs(cookies) do
  v = trim(v)
  if #v > 0 then
    tmp = explode('=', v)
    key = unescape((tmp[1] or ''):gsub('+', ' '))
    value = unescape((tmp[2] or ''):gsub('+', ' '))
    parsed[key] = value
  end
end
ophal.cookies = parsed

function write(s)
  ngx.print(s)
end
io.write = write

function headerCookieSetString(name, value, expires, path, domain)
  return ('%s=%s; domain=%s; expires=%s; path=%s'):format(name, value, domain, ngx.cookie_time(expires+time()), path)
end

function header(n, v)
  if n == 'status' then
    ngx.status = v
  else
    if type(v) == 'function' then
      v = v()
    end
    ngx.header[n] = v
  end
end

--[[
  Redirect to raw destination URL.
]]
function redirect(dest_url, http_response_code)
  shutdown_ophal()
  ngx.redirect(dest_url, http_response_code or ngx.HTTP_MOVED_TEMPORARILY)
end

do
  local body
  function request_get_body()
    local file = {}

    if body == nil then
      ngx.req.read_body()
      -- try from memory
      body = ngx.req.get_body_data()
      if body == nil then
        file.name = ngx.req.get_body_file()
        if file.name then
          file.handle = io.open(file.name)
          body = file.handle:read '*a'
        else
          body = ''
        end
      end
    end
    return body
  end
end

function server_exit()
  ngx.exit(ngx.HTTP_OK)
end

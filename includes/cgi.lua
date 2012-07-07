local io_write, write, buffer = io.write, io.write, env.output_buffer
local time, date, exit = os.time, os.date, os.exit
local tinsert, explode = table.insert, seawolf.text.explode
local tconcat = table.concat

-- output functions
function print(s)
  write(tostring(s))
end

function echo(...)
  for _, v in pairs({...}) do
    write(tostring(v))
  end
end

-- Browser cache control
if settings.cache and _SERVER [[HTTP_IF_MODIFIED_SINCE]] ~= nil then
  print [[Status: 304 Not Modified
Cache-Control: must-revalidate

]]
  exit()
end

-- Redirect to mobile domain name
if settings.mobile then
  local domain_name = settings.mobile.domain_name
  if settings.mobile.redirect and mobile.detect.isMobile() and _SERVER [[HTTP_HOST]] ~= domain_name then
    io.write(([[Content-Type: text/html
X-Powered-By: %s
Location: http://%s

Redirecting to <a href="http://%s">http://%s</a>.]]):format(ophal.version, domain_name, domain_name, domain_name))
    os.exit()
  end
end

-- Headers
if settings.sessionapi then
  -- Look for session cookie
  cgic.cookies(ophal.cookies)
  local session_id = cgic.cookieString([[session-id]], 36)
  -- if session ID is not valid then set a new ID
  if not uuid.isvalid(session_id) then
    session_id = uuid.new()
    cgic.headerCookieSetString([[session-id]], session_id,
      60*60*24*365*12, base_path, _SERVER [[SERVER_NAME]] or [[]])
  end
  -- free CGI memory
  cgic.exit()
end

print(([[Content-type: text/html; charset=utf-8
X-Powered-By: %s
Expires: Sun, 19 Nov 1978 05:00:00 GMT
Last-Modified: %s
Cache-Control: store, no-cache, must-revalidate, post-check=0, pre-check=0
Keep-Alive: timeout=15, max=90

]]):format(ophal.version, date([[!%a, %d %b %Y %X GMT]], time(date([[*t]])) - 15*60)))

-- Parse query string
require [[socket.url]]
local unescape = socket.url.unescape
local list = explode([[&]], _SERVER [[QUERY_STRING]] or [[]])
local parsed = {}
if list then
  local tmp, key, value
  for _, v in pairs(list) do
    if #v > 0 then
      tmp = explode([[=]], v)
      key = unescape((tmp[1] or [[]]):gsub([[+]], [[ ]]))
      value = unescape((tmp[2] or [[]]):gsub([[+]], [[ ]]))
      parsed[key] = value
    end
  end
end
_GET = parsed

-- output buffering
if settings.output_buffering then
  write = function (s)
    local type_ = type(s)
    if type_ ~= [[string]] then
      s = ([[(%s)]]):format(type_)
    end
    tinsert(buffer, #buffer + 1, s) 
  end
end

function output_clean()
  for k, v in pairs(env.output_buffer) do
    output_buffer[k] = nil -- wipe buffer
  end
  -- turn off output buffering
  write = io_write
  settings.output_buffering = false
end

function output_get_clean()
  local output = tconcat(env.output_buffer)
  output_clean()
  return output
end

function output_flush()
  print(output_get_clean())
end

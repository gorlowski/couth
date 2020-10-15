local utf8 = require('utf8')

--
--  General purpose library helper functions
--
local M = {}
function M.count_keys(t)
  local n=0
  for _,_ in pairs(t) do n=n+1 end
  return n
end

--
--  Working with os processes
--
M.ps = {}
function M.ps.is_running(process_name)
  local fd = io.popen("pgrep " .. process_name)
  local pid = fd:read("*all")
  return (tonumber(pid) ~= nil)
end

--
--  file path functions (like python os.path)
--
M.path = {}
function M.path.file_exists(file_name)
  ret = false
  f = io.open(file_name, 'r')
  if f then
    ret = true
    f:close()
  end
  return ret
end

-- Error Code 21 -> EISDIR  -> File Is a directory
function M.path.is_dir(file_name)
  ret = false
  local f = io.open(file_name, "r")
  local ok, err, code = f:read("*all")
  f:close()
  return code == 21
end

--
--  string functions
--
M.string = {}
function M.string.max_len(t)
  local ret=0, l
  for _,v in pairs(t) do
    if v and type(v)=='string' then
      l = utf8.len(v)
      if l>ret then ret=l end
    end
  end
  return ret
end

-- str:len() returns byte count not character
-- length. Assume that we're using utf8 and use
-- utf8.len(str) to get the character count
function M.string.rpad(str, width)
  -- return str .. string.rep(' ', width - str:len())
  return str .. string.rep(' ', width - utf8.len(str))
end

return M

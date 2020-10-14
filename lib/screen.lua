---------------------------------------------------------------------------
--
--    couth screen library
--
--    Dim, brighten or turn off your display
--
--    The control to turn off your display only works
--    with xwindows/xorg because it uses xset (xset dpms force off)
--
--    Usage Examples:
--
--    -- configure the directory where screen display backlight brightness
--    -- controls are located. For intel graphics cards, this would be:
--    couth.config.backlight_control_dir = "/sys/class/backlight/intel_backlight"
--
--    -- Note that if we do not explicitly set backlight_control_dir, couth will try
--    -- to auto-detect it. The auto-detection will work for some linux kernel versions
--    -- and for some intel and ATI video drivers, but it may not work for all hardware
--    -- or kernel versions.
--
--    couth.screen.set_brightness(0.1)    -- make the display 10% brighter
--    couth.screen.set_brightness(-0.1)   -- make the display 10% dimmer
--
--    -- make the display 10% dimmer, specifying the location of the backlight controls
--    -- in /sys as a parameter
--    couth.screen.set_brightness(-0.1, {control_dir="/sys/class/backlight/intel_backlight"}))
--
---------------------------------------------------------------------------

require('math')

local M = {}
local couth = require('couth.couth')
local __backlight_control_dir = nil
local __max_brightness = nil

local _default_sys_backlight_control_dir = function()
  if __backlight_control_dir == nil then
    local d = couth.config.backlight_control_dir
    if d ~= nil and couth.path.is_dir(d) then
      __backlight_control_dir = d
    else
      for _,subdir in ipairs({"intel_backlight", "acpi_video0"}) do
        d = "/sys/class/backlight/" .. subdir
        if couth.path.is_dir(d) then
          __backlight_control_dir = d
          break
        end
      end
    end
  end
  return __backlight_control_dir
end

local _sys_backlight_control_dir = function(opts)
  if opts == nil then opts = {} end
  return (opts.control_dir or _default_sys_backlight_control_dir())
end

-- TODO: add error-handling and display a popup message if file cannot
-- be read
local _read_file_int = function(file_name)
  local fd = io.open(file_name, "r")
  local contents, error_message, error_code = fd:read("*all")
  fd:close()
  if contents then
    return math.floor(tonumber(contents))
  else
    return nil
  end
end

-- TODO: error-handling
local _write_file_int = function(file_name, val)
  local fd = io.open(file_name, "w")
  fd:write(tostring(math.floor(val)))   -- ensure that the output has no decimal point
  fd:close()
end

local _max_brightness = function(opts)
  if __max_brightness == nil then
    __max_brightness = _read_file_int(_sys_backlight_control_dir(opts) .. "/" .. "max_brightness")
  end
  return __max_brightness
end

local _current_brightness_file = function(opts)
  return _sys_backlight_control_dir(opts) .. "/" .. "brightness"
end

local _current_brightness = function(opts)
  return _read_file_int(_current_brightness_file(opts))
end

-- If the level is between 0 and 1, set it to a percentage of the current
-- brightness. So if level == 0.1, increase the brightness 10%. If it is -0.1,
-- decrease the brightness 10%. If level is an integer, set the brightness
-- to the value of level.
function M.set_brightness(level, opts)
  local new_val = level
  local max_brightness = _max_brightness(opts)
  if math.abs(level) > 0 and math.abs(level) < 1 then
    new_val = _current_brightness(opts) + (level * max_brightness)
  end
  new_val = math.max(new_val, 0)
  new_val = math.min(new_val, max_brightness)
  _write_file_int(_current_brightness_file(opts), new_val)
end

-- TODO: add a function for turning the backlight on or off
-- TODO: add a visual indicator that shows the current display brightness as it
--       is adjusted

return M

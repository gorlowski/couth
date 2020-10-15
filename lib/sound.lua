---------------------------------------------------------------------------
--
--    couth sound volume library
--
--    This only works with ALSA (not OSS). You must have amixer on your path
--    for this to work. If you use pulse audio with ALSA then you must have
--    pactl on your path as well for toggling mute state.
--
--    Usage Examples:
--
--      -- You can set couth.config.alsa_controls in your rc.lua to set
--      -- the controls that will appear in the volume display. You probably want
--      -- to set this to "Master" as well as other output controls, such as
--      -- "Headphone" and "Speaker". E.g.,
--      couth.config.alsa_controls = {"Master", "Speaker", "Headphone" }
--
--      -- If you use multiple sound cards or output devices that have different
--      -- controls, you may want to instead pass this as a parameter when
--      -- you display the volume, e.g.:
--      couth.sound.display_volume_state({alsa_card_number=1, visible_controls={"Master","Speaker"}})
--
--
--      -- is displayed for all audio controls.
--      -- for all controls is alsa_card_number rather than explicitly passing it to the
--      -- couth.sound functions if you only use 1 sound card but couth's auto-discovery
--      -- does not detect the correct card for some reason. Example:
--      couth.config.alsa_card_number = 0 (this would pass -c0 to amixer and other alsa commands)
--
--      -- Display the the volume state for all alsa controls.
--      -- Here we specify that we want to see the volume state for alsa card1.
--      -- If opts are omitted or alsa_card_number
--      -- is not specified then couth will attempt to infer the card number.
--      -- If you use multiple sound output devices then you probably want to
--      -- explicitly set alsa_card_number. If you use a single sound card
--      -- (most common usage) then inferring the card number will probably
--      -- work fine.
--      couth.sound.display_volume_state({alsa_card_number=1})
--
--      -- Display the volume state for all alsa controls associated with the
--      -- first sound card that is discovered
--      couth.sound.display_volume_state()
--
--      -- You can set couth.config.alsa_card_number in your rc.lua to set
--      -- the default alsa_card_number rather than explicitly passing it to the
--      -- couth.sound functions if you only use 1 sound card but couth's auto-discovery
--      -- does not detect the correct card for some reason. Example:
--      couth.config.alsa_card_number = 0 (this would pass -c0 to amixer and other alsa commands)
--
--      -- Show the the volume for all alsa controls associated with card 1,
--      -- highlighting the Master volume in green
--      couth.sound.display_volume_state({highlight='Master', alsa_card_number = 1})
--
--      -- Set the the volume for CONTROL to NEW_VALUE, and
--      -- return bar indicators that displays all volumes with
--      -- the indicator for CONTROL highlighted.
--      --
--      -- NOTE: NEW_VALUE can be any string that "amixer" will
--      -- accept as an argument, e.g., 3dB-, 3dB+, etc.
--      couth.sound.set_volume('Master', NEW_VALUE)
--
--      -- Same as the above but explicitly set the Master control for card number 0
--      couth.sound.set_volume('Master', NEW_VALUE, {alsa_card_number=0})
--
--      -- Toggle the mute state for audio outputs
--      -- It used to be possible to toggle each output independently with amixer,
--      -- but if you run pulseaudio then amixer cannot toggle them independently.
--      -- If you want to quickly mute, I think it is reasonable for most cases
--      -- to just mute all audio outputs rather than toggling them individually
--      couth.sound.toggle_mute()
--
--      -- Explicitly toggle the mute state for card number 0 rather than the
--      -- first card that is discovered.
--      couth.sound.toggle_mute({alsa_card_number=0})
--
---------------------------------------------------------------------------

local M = {}
local couth = require('couth.couth')

-- Returns the numeric index (zero-indexed) of the alsa "card" that is used to control
-- actual mixer output volumes. This will likely be 0 or 1. Because there is no core
-- function for getting a directory listing in lua, this will just assume that there
-- are no more than 4 cards, count down in reverse order, and return the first card
-- index that has a "Master" control. Otherwise, assume card0
local function _guess_alsa_card_number()
  ret = 0
  for _,n in ipairs({3,2,1}) do
    if couth.path.file_exists("/sys/class/sound/card" .. n) then
      local fd = io.popen("amixer -c" .. n .. " sget Master")
      local amixer_out = fd:read("*all")
      fd:close()
      if string.match(amixer_out, "Master") then
        return n
      end
    end
  end
  return ret
end

local volume_pattern = 'Playback.*%[(%d+)%%%]'
local mute_pattern = '%[(o[nf]+)%]'
local control_pattern = "^Simple mixer control '(%a+)'"

local __default_card_number = nil
local default_card_number = function()
  if __default_card_number == nil then
    __default_card_number = _guess_alsa_card_number()
  end
  return __default_card_number
end

local __use_pulse_audio = nil
local use_pulse_audio = function()
  if __use_pulse_audio == nil then
    if couth.config.use_pulse_audio ~= nil then
      __use_pulse_audio = couth.config.use_pulse_audio
    else
      __use_pulse_audio = couth.ps.is_running("pulseaudio")
    end
  end
  return __use_pulse_audio
end

local _amixer_command = function(opts)
  if opts == nil then
    opts = {}
  end
  card_number = (opts.alsa_card_number or couth.config.alsa_card_number or default_card_number())
  return "amixer -c" .. card_number
end

-- get all alsa volumes as a table:
function _get_volumes(opts)
  local fd = io.popen(_amixer_command(opts) .. " scontents")
  local volumes = fd:read("*all")
  fd:close()

  local n=1
  local ret = {}

  local controls = {}
  for i,v in pairs(opts.visible_controls or couth.config.alsa_controls) do controls[v]=1 end

  local m, ctrl, vol, mute
  for line in volumes:gmatch("[^\n]+") do
    if couth.count_keys(controls) > 0 then
      _,_,m = line:find(control_pattern)
      if m and controls[m] then
        ctrl = m
      else
        _,_,vol = line:find(volume_pattern)
        if ctrl and vol and controls[ctrl] then
          ret[ctrl] = {vol = vol}
          _,_,mute=line:find(mute_pattern)
          if mute then ret[ctrl]['mute'] = mute end
          controls[ctrl], vol, mute, ctrl = nil
        end
      end
    end
  end
  return ret
end

local function _mute_indicator(on_or_off)
  if not on_or_off then return '   ' end
  if on_or_off == 'on' then
    return '[ ]'
  end
  -- off means the ctrl is mute
  return '[M]'
end

-- I have this here so I can write display output
-- to a temp file to compare the visual appearance
-- of different display styles
local function _write_output_to_file(file,str)
  fd = io.open(file,'w')
  fd:write(str)
  fd:close()
end

--
--  valid keys for opts:
--
--  highlight: the name of an alsa control that we want to highlight in
--             the display indicator. If this is nil then no controls will be
--             highlighted in the display. Use this to signify the
--             control that was just modified -- i.e., if we are
--             adjusting the Master volume then Master will be
--             highlighted and others will not be. This helps give us
--             a visual indicator of the volume control we are adjusting
--             so we know if we accidentally hit the wrong key.
--
function M.display_volume_state(opts)
  local ret = {}
  if opts == nil then
    opts = {}
  end
  local vol, mute
  local volumes = _get_volumes(opts)
  local visible_controls = (opts.visible_controls or couth.config.alsa_controls)
  local pad_width = couth.string.max_len(visible_controls)

  for _,ctrl in ipairs(visible_controls) do
    if volumes[ctrl] then
      local prefix, suffix = '',''
      if ctrl == opts.highlight then
        prefix,suffix = '<span color="green">',"</span>"
      end
      table.insert(ret, prefix .. couth.string.rpad(ctrl, pad_width) .. ': '
        .. _mute_indicator(volumes[ctrl]['mute']) .. ' '
        .. couth.indicator.bar_indicator(volumes[ctrl]['vol']) .. suffix)
    end
  end
  -- _write_output_to_file("/tmp/couth_volume_display.out", table.concat(ret,"\n"))
  return table.concat(ret,"\n")
end

function M.toggle_mute(opts)
  if use_pulse_audio() then
    io.popen("pactl set-sink-mute 0 toggle"):close()
  else
    io.popen(_amixer_command(opts) .. " set Master toggle")
  end
  return M.display_volume_state(opts)
end

--
--  level can be "toggle" to toggle mute/unmute or any other string
--  that amixer can recognize 3dB+
--
function M.set_volume(ctrl, level, opts)
  if opts == nil then
    opts = {}
  end
  io.popen(_amixer_command(opts) .. " set " .. ctrl .. ' ' .. level):close()
  return M.display_volume_state({alsa_card_number = opts.alsa_card_number,
      visible_controls=(opts.visible_controls or couth.config.alsa_controls),
      highlight = ctrl})
end

return M

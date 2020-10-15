---------------------------------------------------------------------------
--
--    couth.lua   -- core library for the couth awesome wm project
--
--    @author Greg Orlowski
--    @contributor ▟ ▖▟ ▖
--
--    @copyright 2020 Greg Orlowski
--
---------------------------------------------------------------------------

couth = { path = {}, string = {}, indicator = {}, notifier = {id=nil} }

local io = require 'io'
local naughty = naughty or  require 'naughty'

local naughty = require("naughty")
local couth_lib = require("couth.lib")

-- Initialize couth.config only if it is non-nil. This allows the user to
-- optionally initialize couth.config before this module is loaded
local couth = couth or {}
if not couth.config then couth.config = {} end

-- Add couth_lib to the couth namespace
for k,v in pairs(couth_lib) do couth[k]=v end

function couth.config:set_default(k,v)
  if self[k] == nil and v ~= nil then
    self[k] = v
  end
end

function couth.config:set_defaults(t)
  for k,v in pairs(t) do
    self:set_default(k, v)
  end
end

--
--  This is the default configuration for couth modules.
--  Modify this table to change the defaults.
--
couth.config:set_defaults({
  -- The number of '|' characters that will be used to represent the volume
  -- indicator bar
  indicator_max_bars = 20,

  -- these are the alsa controls that can be controlled or displayed
  -- by couth. To get a list of possible values, execute this in a shell:
  --
  --    amixer -c0 scontrols |sed -e "s/.* '//" -e "s/'.*//"
  --
  -- (use -c1 if your mixer controls are associated with card1 not card0)
  alsa_controls = {
    'Master',
    'Speaker',
    'Headphone',
  },

  -- If you want uniform bar indicators that use the same character for each
  -- bar, use (you may prefer a different bar character, such as one of the
  -- thicker bar characters below):
  -- indicator_bars = {'|'},

  -- You can also configure your indicator bar to use a series of
  -- increasingly-thicker characters like this:
  indicator_bars = {'▏','▎','▍','▌','▋','▊','▉','█'},

  -- Or increasingly-taller characters like this:
  -- indicator_bars = {'▁','▂','▃','▄','▅','▆','▇','█'},

  -- outer left and outer right character of the bar
  indicator_borders = {'[',']'},

  -- Initialize to nil here. If the value is nil then the couth sound library will
  -- try to auto-detect the card number
  alsa_card_number = nil,

  -- Set use_pulse_audio to true or false to tell couth whether to use pulse
  -- audio controls for toggling audio output mute state. If this configuration
  -- setting is nil (unset) then couth will attempt to autodetect whether or not
  -- pulse audio is being used.
  use_pulse_audio = nil,

  -- The font to use for notifications. You should use a mono-space font so
  -- the columns are evenly aligned.
  notifier_font = 'mono 22',
  notifier_position = 'top_right',
  notifier_timeout = 5,
})

-- Return

local __full_indicator_bar_char_table = nil
local full_indicator_bar_char_table = function()
  if __full_indicator_bar_char_table == nil then
    local bar_chars = couth.config.indicator_bars
    local i
    __full_indicator_bar_char_table = {}
    for i=1,couth.config.indicator_max_bars do
      table.insert(__full_indicator_bar_char_table, bar_chars[math.ceil((#bar_chars/couth.config.indicator_max_bars)*i)])
    end
  end
  return __full_indicator_bar_char_table
end

--
--  indicator functions
--
couth.indicator = {}
function couth.indicator.bar_indicator(prct)
  local bar_chars = couth.config.indicator_bars
  local border_chars = couth.config.indicator_borders
  local max_bars = couth.config.indicator_max_bars
  local num_bars = math.floor(max_bars * (prct / 100.0))
  local display_bar

  if #bar_chars == 1 then -- shortcut
    display_bar = string.rep(bar_chars[1], num_bars)
  else
    display_bar = table.concat({table.unpack(full_indicator_bar_char_table(), 1, num_bars)})
  end
  return border_chars[1] .. couth.string.rpad(display_bar, max_bars) .. border_chars[2]
end

--
--  notifier
--
function couth.notifier:notify(msg)
  self.id = naughty.notify({
    text = msg,
    font = couth.config.notifier_font,
    position = couth.config.notifier_position,
    timeout = couth.config.notifier_timeout,
    replaces_id = self.id
  }).id
end

return couth

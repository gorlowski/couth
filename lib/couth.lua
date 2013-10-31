---------------------------------------------------------------------------
--
--    couth.lua   -- shared libaries for the couth awesomewm library
--
--    @author Greg Orlowski
--    @contributor ▟ ▖▟ ▖
--    @copyright 2011 Greg Orlowski
--
--
--
---------------------------------------------------------------------------

couth = { path = {}, string = {}, indicator = {}, notifier = {id=nil} }

local io = require 'io'
local naughty = naughty or  require 'naughty'

--
--  This is the default configuration for couth modules.
--  Modify this table to change the defaults.
--
couth.CONFIG = {

    -- The width of your volume indicators (the max number of | characters to
    -- display)
    INDICATOR_MAX_BARS = 20,

    -- these are the alsa controls that can be controlled or displayed
    -- by couth. To get a list of possible values, execute this in a shell:
    --
    --    amixer scontrols |sed -e "s/.* '//" -e "s/'.*//"
    --
    ALSA_CONTROLS = {
        'Master',
        'PCM',
    },

    -- The font to use for notifications. You should use a mono-space font so
    -- the columns are evenly aligned.
    NOTIFIER_FONT = 'mono 22',
    NOTIFIER_POSITION = 'top_right',
    NOTIFIER_TIMEOUT = 5,

    -- Character to draw the actual bar with
    -- more complex example: {'','▏','▎','▍','▌','▋','▊','▉','█'}
    INDICATOR_BARS = {'|'},

    -- outer left and outer right character of the bar
    INDICATOR_BORDERS = {'[',']'},

}

--
--  general functions
--
function couth.count_keys(t)
  local n=0
  for _,_ in pairs(t) do n=n+1 end
  return n
end


--
--  file path functions (like python os.path)
--
function couth.path.file_exists(fileName)
  doesExist = false
  f = io.open(fileName, 'r')
  if f then
    doesExist = true
    f:close()
  end
  return doesExist
end

--
--  string functions
--
function couth.string.maxLen(t)
  local ret=0, l
  for _,v in pairs(t) do
    if v and type(v)=='string' then
      l = v:len()
      if l>ret then ret=l end
    end
  end
  return ret
end

function couth.string.rpad(str, width)
  return str .. string.rep(' ', width - str:len())
end

--
--  indicator functions
--
function couth.indicator.barIndicator(prct)
    local BAR = couth.CONFIG.INDICATOR_BARS
    local BORDER = couth.CONFIG.INDICATOR_BORDERS
    local maxBars = couth.CONFIG.INDICATOR_MAX_BARS
    local num_bars = maxBars * prct * 0.01
    local full_bars = math.floor(num_bars)
    local bar, space
    if #BAR == 1 then -- shortcut
        bar = string.rep(BAR[1], full_bars)
        space = string.rep(" ", maxBars - full_bars)
    else
        local part_bar = math.floor((num_bars - full_bars) * (#BAR - 1))
        bar = string.rep(BAR[#BAR], full_bars) .. (BAR[part_bar] or "")
        space = string.rep(" ", maxBars - full_bars - (part_bar > 0 and 1 or 0))
    end
    return BORDER[1] .. bar .. space .. BORDER[2]
end

--
--  notifier
--
function couth.notifier:notify(msg)
  self.id = naughty.notify({
    text = msg,
    font = couth.CONFIG.NOTIFIER_FONT,
    position = couth.CONFIG.NOTIFIER_POSITION,
    timeout = couth.CONFIG.NOTIFIER_TIMEOUT,
    replaces_id = self.id
  }).id
end

return couth

==========================================================
couth -- a set of plugins for the awesome window manager
==========================================================

This is a set of plugins that I wrote for `awesome
<http://awesome.naquadah.org/>`_. This was most-recently
updated and tested with awesome verion 4.3.

----------
plugins
----------

couth.sound:

    allows you to get/set the volumes for all your alsa controls (*e.g.*,
    Master volume, Headphone volume, PCM volume, etc.). When you view or change the
    volume, an indicator can be displayed with awesome's `naughty
    <http://awesome.naquadah.org/wiki/Naughty>`_ library. The indicator is a basic
    bar/ascii indicator that looks something like like this::

        Master   : [ ] [|||||||||||||||     ]
        Headphone: [ ] [||||||||||||||      ]
        PCM      :     [||||||||||||||||||||]
        Front    : [ ] [|||||||||||||||||   ]

    They can also be configured to look like this (contributed by user dodo)::

        Master   : [ ] [▏▏▎▎▎▍▍▌▌▌▋▋▊▊▊▉▉███]
        Speaker  : [ ] [▏▏▎▎▎▍▍▌▌▌▋▋▊▊▊▉▉███]
        Headphone:     [                    ]

    Or you might prefer this look::

        Master   : [ ] [▁▁▂▂▂▃▃▄▄▄▅▅▆▆▆▇    ]
        Speaker  : [ ] [▁▁▂▂▂▃▃▄▄▄▅▅▆▆▆▇▇███]
        Headphone:     [                    ]

    For usage and configuration, look at `lib/sound.lua <lib/sound.lua>`_.

couth.screen:

    allows you to increase and decrease the brightness of your screen or
    turn off the display. This only works if your user can write to the
    "brightness" file in /sys that corresponds to your video driver.

    On my system, I added the following udev rules in
    ``/etc/udev/rules.d/backlight.rules`` to ensure that members of the video
    group (including my user) have access to write to the display brightness
    control file::
	
        # See: https://wiki.archlinux.org/index.php/backlight
  			#
        # On my system with intel video, backlight controls are in
        # /sys/class/backlight/intel_backlight. By default, the brightness file
        # in this directory can only be written by root. You can add udev rules
        # to change the group ownership of the brightness file to the video
        # group and make the file group-writable. This allows personal users in
        # the video group to set the backlight brightness by writing to the
        # file.
  		  ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
  		  ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
		
couth.mpc:

    This is similar to the couth.sound library, but it allows you to get/set the
    volume of an mpd server (either localhost or a remote mpd server). Here is
    an example of the output::

        localhost volume: [||||||||||||||||||| ]

    The cool thing about couth.mpc is that you can map the volume +/- keys on a
    laptop to control the volume on, e.g., your media server. I map a combination
    of [meta, shift, XF86AudioRaiseVolume]/[meta, shift, XF86AudioLowerVolume]
    on my laptop to raise/lower the volume on the mini-itx server plugged into
    my living room stereo.

---------------
Installation
---------------

- Download the couth source tree (with git, from a tarball, or however else you
  manage to get it) to some directory on your machine.

- Run ``make install`` to create symlinks from ``$HOME/.config/awesome/couth``
  to lib directory where you installed the actual files (``$PWD/lib``).

- Configure your ``rc.lua`` to add::

    -- you MUST require this to use ANY couth modules:
    local couth = require('couth.couth')

    -- These are optional. Only require the ones that you want to use.
    couth.sound = require('couth.sound')
    couth.screen = require('couth.screen')


- To customize your couth configuration, you can call the following in your
  ``rc.lua``::

    couth.config:update({

      alsa_card_number = 0,     -- OPTIONAL. This is auto-discovered if unspecified.

      indicator_bars = {'▁','▂','▃','▄','▅','▆','▇','█'},   -- alternative bar style

    })

- Then add key bindings to couth functions.

----------------------
rc.lua configuration
----------------------

There is some auto-detection written into the couth library to discover some
information that couth needs at runtime such as whether your system is running
pulse audio and the location of your video device backlight controls. You can
override this auto discovery and also change some configuration settings by
calling::

  couth.config:update({

    -- explicitly use pulse audio controls for toggling mute state. You probably
    -- should only set this if you are trying to work around a glitch
    use_pulse_audio = true,       
    
    -- explicitly use the audio controls for card1 rather than the first audio
    -- card that is auto-discovered.  Other devices may use card0 or possibly a
    -- different card (card2). You should probably not set this explicitly unless
    -- your system has multiple audio cards. This number should be the same value
    -- that you would pass to the card parameter of amixer or alsamixer (e.g., 
    -- alsamixer -c1)
    alsa_card_number = 1,         

    -- Set the audio volume controls that you would like to see when you view or change
    -- a volume setting. If you are only interested in the Master volume, you may
    -- set this to just: alsa_controls = {'Master'}
    alsa_controls = {
        'Master',
        'Speaker',
        'Headphone',
    },

  })

Search for ``couth.config:update`` in ``lib/couth.lua`` to see all the
available configuration options.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
couth.sound key binding examples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here is an example of using your keyboard volume +/- buttons to
increase/decrease your Master alsa volume. This also binds the mute key on your
keyboard to toggle the mute/unmute status of your Master volume.::

    awful.key({ }, "XF86AudioLowerVolume",   function () couth.notifier:notify( couth.sound.set_volume('Master','3dB-')) end,
    awful.key({ }, "XF86AudioRaiseVolume",   function () couth.notifier:notify( couth.sound.set_volume('Master','3dB+')) end,

If you want to explicitly adjust the Headphone control rather than the Master control, you can do something like::

    awful.key({ "Control" }, "XF86AudioLowerVolume",    function () couth.notifier:notify( couth.sound.set_volume('Headphone','3dB-')) end,
    awful.key({ "Control" }, "XF86AudioRaiseVolume",    function () couth.notifier:notify( couth.sound.set_volume('Headphone','3dB+')) end,

To toggle the mute state of your audio outputs::

    awful.key({}, "XF86AudioMute", function () couth.notifier:notify( couth.sound.toggle_mute()) end,
              {description = "toggle mute for audio outputs", group = "awesome"}),

See current volume levels (but do not change any of them)::

    awful.key({ modkey }, "v", function () couth.notifier:notify( couth.sound.display_volume_state() ) end,

Bind keys to increase or decrease the screen display backlight in 10% increments::

    awful.key({}, "XF86MonBrightnessDown",   function () couth.screen.set_brightness(-0.1) end,
              {description = "decrease screen brightness", group = "awesome"}),

    awful.key({}, "XF86MonBrightnessUp",   function () couth.screen.set_brightness(0.1) end,
              {description = "increase screen brightness", group = "awesome"}),


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
couth.mpc key binding examples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*NOTE*: I have not recently maintained couth.mpc because I have not been using mpd/mpc ever since
the motherboard failed on my home media server. I will test + fix the couth.mpc plugin once I get
a chance to resurrect my old media server.

This example binds modkey + shift + volume keys to increase/decrease or view
the volume on the mpd server running on a host named "pizza"::

    awful.key({ modkey, "Shift" }, "XF86AudioLowerVolume",    function () couth.notifier:notify( couth.mpc.set_volume('pizza','-5')) end,
    awful.key({ modkey, "Shift" }, "XF86AudioRaiseVolume",    function () couth.notifier:notify( couth.mpc.set_volume('pizza','+5')) end,
    awful.key({ modkey, "Shift" }, "v",                       function () couth.notifier:notify( couth.mpc.get_volume('pizza') ) end,


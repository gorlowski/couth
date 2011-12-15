==========================================================
couth -- a set of plugins for the awesome window manager
==========================================================

This is a set of plugins that I wrote for `awesome
<http://awesome.naquadah.org/>`_.

----------
plugins
----------

couth.alsa:

    allows you to get/set the volumes for all your alsa controls (*e.g.*,
    Master volume, Headphone volume, PCM volume, etc.). When you view or change the
    volume, an indicator can be displayed with awesome's `naughty
    <http://awesome.naquadah.org/wiki/Naughty>`_ library. The indicator is a basic
    bar/ascii indicator that looks something like like this::

        Master   : [ ] [|||||||||||||||     ]
        Headphone: [ ] [||||||||||||||      ]
        PCM      :     [||||||||||||||||||||]
        Front    : [ ] [|||||||||||||||||   ]

couth.mpc:

    This is similar to the couth.alsa library, but it allows you to get/set the
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
    require('couth.couth')

    -- These are optional. Only require the ones that you want to use.
    require('couth.alsa')
    require('couth.mpc')

- Update your ``rc.lua`` to add a couth.CONFIG section to customize couth, and
  then add key bindings to couth functions.

----------------------
rc.lua configuration
----------------------

I have this in my rc.lua to specify the alsa controls to use with the
couth.alsa plugin::

    couth.CONFIG.ALSA_CONTROLS = {
         'Master',
         'Headphone',
         'PCM',
         'Front'
    }

Search for ``couth.CONFIG`` in ``lib/couth.lua`` to see all the available
configuration options.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
couth.alsa key binding examples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here is an example of using your keyboard volume +/- buttons to
increase/decrease your Master alsa volume. This also binds the mute key on your
keyboard to toggle the mute/unmute status of your Master volume.::

    awful.key({ }, "XF86AudioLowerVolume",   function () couth.notifier:notify( couth.alsa:setVolume('Master','3dB-')) end),
    awful.key({ }, "XF86AudioRaiseVolume",   function () couth.notifier:notify( couth.alsa:setVolume('Master','3dB+')) end),
    awful.key({ }, "XF86AudioMute",          function () couth.notifier:notify( couth.alsa:setVolume('Master','toggle')) end),

I bind control + volume keys to adjust my Headphone volume::

    awful.key({ "Control" }, "XF86AudioLowerVolume",    function () couth.notifier:notify( couth.alsa:setVolume('Headphone','3dB-')) end),
    awful.key({ "Control" }, "XF86AudioRaiseVolume",    function () couth.notifier:notify( couth.alsa:setVolume('Headphone','3dB+')) end),
    awful.key({ "Control" }, "XF86AudioMute",           function () couth.notifier:notify( couth.alsa:setVolume('Headphone','toggle')) end),


See current volume levels (but do not change any of them)::

    awful.key({ modkey }, "v",                       function () couth.notifier:notify( couth.alsa:getVolume() ) end),

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
couth.mpc key binding examples
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This example binds modkey + shift + volume keys to increase/decrease or view
the volume on the mpd server running on a host named "pizza"::

    awful.key({ modkey, "Shift" }, "XF86AudioLowerVolume",    function () couth.notifier:notify( couth.mpc:setVolume('pizza','-5')) end),
    awful.key({ modkey, "Shift" }, "XF86AudioRaiseVolume",    function () couth.notifier:notify( couth.mpc:setVolume('pizza','+5')) end),
    awful.key({ modkey, "Shift" }, "v",                       function () couth.notifier:notify( couth.mpc:getVolume('pizza') ) end)


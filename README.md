hdd-temp
=======

FreeBSD tool to trigger the temperature of all attached hdd's
Data is presented in a nice colorized way (green, yellow and red)

Requirements:
------------------
* smartctl (sysutils/smartmontools)
* must be run as root


create-jail
=======

FreeBSD tool to create a jail on non-zfs systems easily


Requirements:
------------------
* /usr/src must be compiled
* must be run as root


zfs-snapshot
=======

An automated zfs snapshot creation script, Ideally used for cron.
Let's you specify which zfs filesystem to snapshot and also how many old snapshots to keep.

Requirements:
------------------
* ZFS ;-)

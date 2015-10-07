#!/bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <cytopia@everythingcli.org> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return cytopia
# ----------------------------------------------------------------------------
#
# To use as previous version in samba:
#   follow symlinks     = yes
#   wide links          = yes
#   vfs objects         = shadow_copy2
#   shadow:snapdir      = .zfs/snapshot
#   shadow:localtime    = yes               ; use local server timezone rather than GMT
#   shadow:sort         = desc              ; descending sort makes more sense
#   shadow:format       = %Y-%m-%d_%H.%M.%S ; format (see below for LABEL) - They must match!!
#



# ------------------- Settings -------------------

# How many snapshots to keep?
# All older snapshots will be deleted.
KEEP=10

# Which ZFS filesystem to snapshot?
# E.g.: tank/data/files
# Note: Do not append a slash at the end!
FILESYSTEM="tank/files/development"



# ------------------- Binaries -------------------
ZFS="/sbin/zfs"
GREP="/usr/bin/grep"
WC="/usr/bin/wc"
DATE="/bin/date"
EXPR="/bin/expr"



# ------------------- Create new snapshot -------------------

# Label to use for snapshot
LABEL=`${DATE} +"%Y-%m-%d_%H.%M.%S"`
`${ZFS} snapshot ${FILESYSTEM}@${LABEL}`


# ------------------- Delete old snapshots -------------------

# Count current available snapshots
# The '@' makes sure we do not count childs of that snapshot.
COUNT=`${ZFS} list -t snapshot | ${GREP} ${FILESYSTEM}@ | ${WC} -l`

# Get the difference between the number you want to keep and the number that actually exists
DIFF=`$EXPR $COUNT - $KEEP`


# Are there more snapshots than you want to keep?
if [ $DIFF -gt 0 ]; then

  # get older snapshots for deletion
	for snapshot in `${ZFS} list -t snapshot | ${GREP} ${FILESYSTEM}@ | head -n${DIFF} | awk '{print $1}'`
	do
		# delete the undesired snapshots
		`${ZFS} destroy ${snapshot}`
	done
fi

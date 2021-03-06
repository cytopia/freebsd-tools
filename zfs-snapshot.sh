#!/usr/bin/env sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <pantu39@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Pantu
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

progname=$0

usage ()
{
    cat <<EOF
Usage: $progname  [-d <name>] [-l <name>] [-k <num>]

Required Options:
  -d <name>   : Specify the zfs dataset to create the snapshot for
  -l <name>   : Specify the label of the snapshot
  -k <num>    : Only keep X snapshots and delete the rest

Example:
  $progname -d tank/files/data -l %Y-%m-%d_%H.%M.%S -k 5

EOF
    exit 0;
}

while getopts ":h::d:l:k:" opt;
do
    case $opt in
        h)  usage;
            ;;
        d)  d=$OPTARG;
            ;;
        l)  l=$OPTARG;
            ;;
        k)  k=$OPTARG;
            ;;
        ?)  usage;
            ;;
    esac
done
shift $(($OPTIND - 1));


# If required vars are not set, display usage
if [ -z "${d+xxx}" ]; then usage; fi
if [ -z "${l+xxx}" ]; then usage; fi
if [ -z "${k+xxx}" ]; then usage; fi

# ------------------- Settings -------------------

# How many snapshots to keep?
# All older snapshots will be deleted.
KEEP=$k

# Which ZFS filesystem to snapshot?
# E.g.: tank/data/files
# Note: Do not append a slash at the end!
FILESYSTEM=$d



# ------------------- Binaries -------------------
ZFS="/sbin/zfs"
GREP="/usr/bin/grep"
WC="/usr/bin/wc"
DATE="/bin/date"
EXPR="/bin/expr"



# ------------------- Create new snapshot -------------------

# Label to use for snapshot
LABEL=`${DATE} +"${l}"`
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

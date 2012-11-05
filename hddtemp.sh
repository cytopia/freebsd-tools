#/!bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <pantu39@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Pantu
# ----------------------------------------------------------------------------
#


# Get all attached devices (one per line)
# and store them temporarily
DEVLIST=`egrep 'ad[0-9]|cd[0-9]' /var/run/dmesg.boot | awk '{sub(/:/, ""); print $1}'`

# Loop through all lines
for line in $DEVLIST
do
        dev=$line
        bus=`cat /var/run/dmesg.boot |grep "${dev} at" |grep target | awk '{print $3}'`
        name=`camcontrol identify /dev/${dev} | grep "device model" | awk '{ $1=$2=""; print $0}'`
        temp=`smartctl -d atacam -A /dev/${dev} | grep Temperature_Celsius | awk '{print $10}'`

        case $temp in
                ''|*[!0-9]*) temp="n.a." ;;
                *) temp="${temp} C" ;;
        esac

        echo -e "$temp\t${bus}:${dev}\t${name}"

done

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
DEVLIST=`camcontrol devlist | awk '{print $NF;}' | awk '{sub(/,/, " "); sub(/\(/, ""); print $1}' > /tmp/hddtemp.tmp`

# Loop through all lines
while read line
do
        dev=$line
        bus=`dmesg |grep "${dev} at" |grep target | awk '{print $3}'`
        name=`camcontrol identify /dev/${dev} | grep "device model" | awk '{ $1=$2=""; print $0}'`
        temp=`smartctl -d atacam -A /dev/${dev} | grep Temperature_Celsius | awk '{print $10}'`

        echo -e "$temp C\t${bus}:${dev}\t${name}"

done < /tmp/hddtemp.tmp
rm /tmp/hddtemp.tmp


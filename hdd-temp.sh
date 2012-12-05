#!/bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <pantu39@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Pantu
# ----------------------------------------------------------------------------
#


# ---------------------------------- Global Variables --------------------------------- #
# Colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
OFF="\033[0m"


# ---------------------------------- Misc Function ---------------------------------- #

#
# Prequisites,
#  * check if this script is run by root
#  * check if smartctl is installed
#
check_requirements()
{
        # Check if we are root
	if [ "$(id -u)" != "0" ]; then
		echo "This script must be run as root" 1>&2
		exit 1
	fi

	# Check if smartctl exists on the system
	command -v smartctl >/dev/null  || { echo "smartctl not found. (install sysutils/smartmontools)"; exit 1; }
}


#
# Colorize output of temperature (all platforms)
#
colorize_temperature()
{
	temp=$1

	case $temp in
		# no temperature obtained
		''|*[!0-9]*)
			temp="n.a."
			;;
		# temperature is obtained
		*)
			if [ $temp -gt 40 ]; then
				temp="${RED}${temp} C${OFF}"
			elif [ $temp -gt 30 ]; then
				temp="${YELLOW}${temp} C${OFF}"
			else
				temp="${GREEN}${temp} C${OFF}"
			fi
			;;
	esac

	echo $temp
}



# ---------------------------------- Generic Disk Function ---------------------------------- #

#
# Get all devices that are attached to the system
#
get_attached_devices()
{
	DEVS=`sysctl kern.disks | awk '{$1=""; ;print $0}' | awk 'gsub(" ", "\n")' | tail -n500 -r | sed '/^cd[0-9]/d'`
	echo $DEVS
}

get_disk_bus()
{
	dev=$1
	bus=`cat /var/run/dmesg.boot | grep "${dev} at" |grep target | awk '{print $3}'`
	echo $bus
}

get_disk_size()
{
	dev=$1
	size=`diskinfo -v /dev/${dev} | grep bytes | awk '{printf "%.2f\n",($1/(1024*1024*1024))}'`
	echo $size
}

get_disk_speed()
{
	dev=$1
	speed=`cat /var/run/dmesg.boot |grep ${dev}: | grep transfers | awk '{print $2};'`
	echo $speed
}

get_disk_number()
{
	dev=$1
	disk_num=`echo ${dev} | sed 's/[^0-9]*//g'`
	echo $disk_num
}


# ---------------------------------- ATA-Device Functions ---------------------------------- #
get_ata_disk_name()
{
	dev=$1
	name=`cat /var/run/dmesg.boot |grep ${dev}: | grep "<"|grep ">"  | awk 'gsub(/<|>/, "\n");' | awk 'NR==2'`
	echo $name
}

get_ata_disk_temp()
{
	dev=$1
	temp=`smartctl -d atacam -A /dev/${dev} | grep Temperature_Celsius | awk '{print $10}'`
	echo $temp
}


# ---------------------------------- CISS-Device Functions ---------------------------------- #
get_ciss_disk_name()
{
	smartctl=$1
	name=`echo "${smartctl}" | grep "Device Model" | awk '{$1=$2=""} {sub(/^[ \t]+/, ""); print;}'`
	firm=`echo "${smartctl}" | grep "Firmware" | awk ' {$1=$2=""} {sub(/^[ \t]+/, ""); print;}'`
	echo "$name $firm"
}

get_ciss_disk_temp()
{
	smartctl=$1
	temp=`echo "${smartctl}" | grep Temperature_Celsius | awk '{print $10}'`
	echo $temp
}





# ---------------------------------- Main Entry Point ---------------------------------- #

# Check if script can be run
check_requirements


# Loop through all attached devices
for dev in `get_attached_devices`
do
	size=`get_disk_size ${dev}`
	bus=`get_disk_bus ${dev}`
	speed=`get_disk_speed ${dev}`

	# check for HP Smart Array controllers
	if [ $bus == "ciss*" ]; then
		devnum=`get_disk_number ${dev}`
		smartctl=`smartctl -a -T permissive -d cciss,${devnum} /dev/${bus} 2> /dev/null`
		name=`get_ciss_disk_name "${smartctl}"`	# preserve newlines by using "
		temp=`get_ciss_disk_temp "${smartctl}"`
		echo "smartctl -a -T permissive -d cciss,${devnum} /dev/${bus} 2> /dev/null"    # debug
	else
		name=`get_ata_disk_name ${dev}`
		temp=`get_ata_disk_temp ${dev}`
	fi

	temp=`colorize_temperature ${temp}`

	echo -e "$temp\t${bus}:${dev}\t${speed}\t${name} (${size}G)"
done

#eof


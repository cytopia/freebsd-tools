#/!bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <cytopia@everythingcli.org> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return cytopia
# ----------------------------------------------------------------------------
#



# ---------------------------------- Misc Functions --------------------------------- #

show_usage()
{
	script=$1
	echo "Usage:"
	echo "    ${script} /path/to/new/jail_name"
}


#
# Prequisites,
#
check_requirements()
{
	jail_path=$1
	num_args=$2

	# 01) Check if we are root
	if [ "$(id -u)" != "0" ]; then
		echo "This script must be run as root" 1>&2
		exit
	fi

	# 02) check for correct number of parameters
	if [ "$num_args" != "1" ]; then
		echo "Illegal number of arguments"
		show_usage $0
		exit
	fi

	# 03) Check if directory exists
	if [ ! -d "$jail_path" ]; then
		echo "$jail_path does not exist"
		echo "Please create it first"
		exit
	fi

	# 04) Check if directory is already used (not empty)
	if [ "$(ls -A $jail_path)" ]; then
		echo "The directory $jail_path is not empty."
		echo "Make sure to specify an empty (unused) directory"
		exit
	fi

	# 05) ask for requirements
	read -r -p "Did you already do a 'make buildworld' in /usr/src ? [Y/n] " response
	case $response in
		[yY][eE][sS]|[yY])
			echo "good :-)"
			;;
		*)
			echo "This is required. Good Bye!"
			exit
			;;
	esac
}



# ---------------------------------- Action Functions --------------------------------- #

jail_install()
{
	jail_path=$1
	echo ""
	echo "------------------------- INSTALLING SOURCE -------------------------"
	echo ""

	cd /usr/src
	make installworld DESTDIR=$jail_path
	cd /usr/src/etc
	make distribution DESTDIR=$jail_path
}

jail_create_configs()
{
	jail_path=$1
	echo ""
	echo "------------------------- CREATING jail configs -------------------------"
	echo ""

	touch $jail_path/etc/fstab
	touch $jail_path/etc/resolv.conf
	touch $jail_path/etc/rc.conf

	echo "#disable remote logging" >> $jail_path/etc/rc.conf
	echo "syslogd_enable=\"YES\"" >> $jail_path/etc/rc.conf
	echo "syslogd_flags=\"-ss\"" >> $jail_path/etc/rc.conf
	echo "" >> $jail_path/etc/rc.conf
	echo "#disable sendmail" >> $jail_path/etc/rc.conf
	echo "sendmail_enable=\"NONE\"" >> $jail_path/etc/rc.conf
	echo "" >> $jail_path/etc/rc.conf
	echo "#disable rpc bind" >> $jail_path/etc/rc.conf
	echo "rpcbind_enable=\"NO\"" >> $jail_path/etc/rc.conf
	echo "" >> $jail_path/etc/rc.conf
	echo "#prevent lots of jails running cron jobs at the same time" >> $jail_path/etc/rc.conf
	echo "cron_flags=\"\$cront_flags -J 15\"" >> $jail_path/etc/rc.conf
	echo "" >> $jail_path/etc/rc.conf
	echo "#clear /tmp " >> $jail_path/etc/rc.conf
	echo "clear_tmp_enable=\"YES\"" >> $jail_path/etc/rc.conf
}

host_create_configs()
{
	jail_path=$1
	jail_base="$(dirname "$jail_path")"
	jail_name="$(basename "$jail_path")"
	jail_path="${jail_base}/${jail_name}" # prevent double slashes
	
	host_fstab="${jail_base}/fstab.${jail_name}"
	port_mount="/usr/ports       ${jail_path}/usr/ports       nullfs noatime,rw 0 0"
	portsnap_mount="/var/db/portsnap ${jail_path}/var/db/portsnap nullfs noatime,rw 0 0"

	echo ""
	echo "------------------------- CREATING host configs -------------------------"
	echo ""

	# create host fstab for jail
	touch $host_fstab
	
	# automount ports and portsnap
	echo "${port_mount}" >> $host_fstab
	echo "${portsnap_mount}" >> $host_fstab
}




# ------------------------------------- Vars ------------------------------------- #

INSTALL_DIR=$1
NUM_ARGS=$#


# ------------------------------------- Main Entry Point ------------------------------------- #

check_requirements $INSTALL_DIR $NUM_ARGS


echo "Going to create a new jail in $INSTALL_DIR"
read -r -p "Are you sure? [Y/n] " response
case $response in
	[yY][eE][sS]|[yY])
		jail_install $INSTALL_DIR
		jail_create_configs $INSTALL_DIR
		host_create_configs $INSTALL_DIR
		echo ""
		echo "done"
		;;
	*)
		echo "Good Bye!"
		exit
		;;
esac

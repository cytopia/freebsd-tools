#/!bin/sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <pantu39@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Pantu
# ----------------------------------------------------------------------------
#



# ---------------------------------- Global Variables --------------------------------- #

jail_install()
{
        path=$1
        echo ""
        echo "------------------------- INSTALLING SOURCE -------------------------"
        echo ""

        echo "cd /usr/src"
        cd /usr/src
        echo "make installworld DESTDIR=${path}"
        make installworld DESTDIR=$path
        echo "cd /usr/src/etc"
        cd /usr/src/etc
        echo "make distribution DESTDIR=${path}"
        make distribution DESTDIR=$path
}


jail_create_fstab()
{
        path=$1
        echo ""
        echo "------------------------- CREATING /etc/fstab -------------------------"
        echo ""

        echo "touch ${path}/etc/fstab"
        touch $path/etc/fstab
}

jail_create_resolv_conf()
{
        path=$1
        echo ""
        echo "------------------------- CREATING /etc/resolv.conf -------------------------"
        echo ""
        echo "touch ${path}/etc/resolv.conf"
        touch $path/etc/resolv.conf
}

jail_create_rc_conf()
{
        path=$1
        echo ""
        echo "------------------------- CREATING /etc/rc.conf -------------------------"
        echo ""
        echo "touch ${path}/etc/rc.conf"
        touch $path/etc/rc.conf

        echo "writing default values to rc.conf"

        echo "#disable remote logging" >> $path/etc/rc.conf
        echo "syslogd_enable=\"YES\"" >> $path/etc/rc.conf
        echo "syslogd_flags=\"-ss\"" >> $path/etc/rc.conf
        echo "" >> $path/etc/rc.conf
        echo "#disable sendmail" >> $path/etc/rc.conf
        echo "sendmail_enable=\"NONE\"" >> $path/etc/rc.conf
        echo "" >> $path/etc/rc.conf
        echo "#disable rpc bind" >> $path/etc/rc.conf
        echo "rpcbind_enable=\"NO\"" >> $path/etc/rc.conf
        echo "" >> $path/etc/rc.conf
        echo "#prevent lots of jails running cron jobs at the same time" >> $path/etc/rc.conf
        echo "cron_flags=\"\$cront_flags -J 15\"" >> $path/etc/rc.conf
        echo "" >> $path/etc/rc.conf
        echo "#clear /tmp " >> $path/etc/rc.conf
        echo "clear_tmp_enable=\"YES\"" >> $path/etc/rc.conf
}


# ------------------------------------- Pre-Checks ------------------------------------- #

INSTALL_DIR=$1

# check for correct number of parameters
if [ $# != 1 ]; then
        echo "Illegal number of arguments"
        echo ""
        echo "Usage:"
        echo "    ${0} /path/to/new/jail"
        exit;
fi


# ask for requirements
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


# Check if directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "$INSTALL_DIR does not exist"
    echo "Please create it first"
        exit
fi


# Check if directory is already used (not empty)
if [ "$(ls -A $INSTALL_DIR)" ]; then
    echo "The directory $INSTALL_DIR is not empty."
    echo "Make sure to specify an empty unused directory"
    exit
fi


echo "Going to create a new jail in $INSTALL_DIR"
read -r -p "Are you sure? [Y/n] " response
case $response in
        [yY][eE][sS]|[yY])
                jail_install $INSTALL_DIR
                jail_create_fstab $INSTALL_DIR
                jail_create_resolv_conf $INSTALL_DIR
                jail_create_rc_conf $INSTALL_DIR
                echo ""
                echo "done"
                ;;
        *)
                echo "Good Bye!"
                exit
                ;;
esac

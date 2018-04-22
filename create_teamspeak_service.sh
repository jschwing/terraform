#!/usr/bin/env bash

cat <<'EOF' >> /etc/init.d/ts3server
#! /bin/sh
### BEGIN INIT INFO
# Provides:          ts3server
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: TeamSpeak 3 Server
# Description:       Startup Init-Script for TeamSpeak 3 Server
### END INIT INFO

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="TeamSpeak 3 Server"
NAME=ts3server
USER=teamspeak
BINARY=ts3server
BINARY_BIN=/data/teamspeak3-server_linux_amd64
DAEMON=ts3server_startscript.sh
DAEMON_ARGS=inifile=ts3server.ini
PIDFILE=$BINARY_BIN/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$BINARY_BIN/$DAEMON" ] || exit 0

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is presenthttp://dl.4players.de/ts/releases
# and status_of_proc is working.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
  su $USER -s /bin/sh -c "$BINARY_BIN/$DAEMON start $DAEMON_ARGS"
}

#
# Function that stops the daemon/service
#
do_stop()
{
  su $USER -s /bin/sh -c "$BINARY_BIN/$DAEMON stop $DAEMON_ARGS"
}

#
# Function that shows the status of to the daemon/service
#
do_status()
{
  su $USER -s /bin/sh -c "$BINARY_BIN/$DAEMON status $DAEMON_ARGS"
}

case "$1" in
  start)
    log_daemon_msg "Starting $DESC" ""
    do_start
    case "$?" in
      0|1) log_end_msg 0 ;;
      2) log_end_msg 1 ;;
    esac
    ;;
  stop)
    log_daemon_msg "Stopping $DESC" ""
    do_stop
    case "$?" in
      0|1) log_end_msg 0 ;;
      2) log_end_msg 1 ;;
    esac
    ;;
  status)
    do_status
    status_of_proc "$BINARY" "$DESC" && exit 0 || exit $?
    ;;
  restart)
	log_daemon_msg "Restarting $DESC" ""
    do_stop
	case "$?" in
	  0|1)
        do_start
        case "$?" in
          0) log_end_msg 0 ;;
          1) log_end_msg 1 ;; # Old process is still running
          *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
		;;
	esac
	;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|status|restart}"
    exit 3
    ;;
esac

:
EOF
chmod +x /etc/init.d/ts3server
systemctl enable ts3server
systemctl start ts3server

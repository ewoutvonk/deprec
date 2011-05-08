#!/bin/sh

<%

boolean_arguments = MEMCACHED_BOOLEAN_OPTIONS.collect do |name, opt|
  if fetch(name)
		"-#{opt}"
	end
end.compact.join(' ')

value_arguments = MEMCACHED_VALUE_OPTIONS.collect do |name, opt|
  if (value=fetch(name))
		"-#{opt} #{value}"
	end
end.compact.join(' ')

arguments = [ [ "-d", "-P $PIDFILE" ], boolean_arguments, value_arguments ].flatten.join(' ')

%>PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/memcached
NAME=memcached
DESC=memcached
PIDFILE=/var/run/$NAME.pid

test -x $DAEMON || exit 0

set -e

start () {
    start-stop-daemon --start --quiet --exec $DAEMON -- <%= arguments %>
}

stop () {
    start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE --exec $DAEMON
		sleep 1
		killall $DAEMON
    rm -f $PIDFILE
}

restart () {
	stop
	sleep 1
	start
}

case "$1" in
    start)
        echo -n "Starting $DESC: "
		start
        echo "$NAME."
        ;;
    stop)
        echo -n "Stopping $DESC: "
		stop
        echo "$NAME."
        ;;

    restart|force-reload)
        echo -n "Restarting $DESC: "
		restart
        echo "$NAME."
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
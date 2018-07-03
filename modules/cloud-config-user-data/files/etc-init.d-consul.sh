#!/bin/bash
# Cross-platform init.d
#
# THIS FILE MANAGED BY TERRAFORM
#
# Source:
# https://raw.githubusercontent.com/NREL/api-umbrella/3f90e1589619bc4f893c1aaafe26bacd78a1a48a/build/package/files/etc/init.d/api-umbrella
#
# consul
#
# chkconfig: - 85 15
# description: Consul
# processname: consul
# config: /etc/consul.d/*.json

### BEGIN INIT INFO
# Provides:          consul
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Consul
### END INIT INFO

GOMAXPROCS=$(nproc)
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
LEADER_HOSTPORT=$(curl -s consul:8500/v1/status/leader |
                     tr -d \" |
                     sed s/8300$/8301/ )
# By default, we start in client mode, unless /etc/default/.. overrides.
CONSUL_FLAGS_FOR_CLIENT="--join $LEADER_HOSTPORT"

name=consul
desc="Consul"
consul_logfile=/var/log/consul.log
consul_command="sudo -u consul /usr/local/bin/consul"
consul_flags="
     -syslog
     -ui
     -bind=$INTERNAL_IP
     -config-dir=/etc/consul.d
     -data-dir=/var/consul
     -client=0.0.0.0
     -pid-file=/var/run/consul.pid"

touch /var/run/consul.pid
chown consul:consul /var/run/consul.pid

# This keeps us compatible in ubuntu-land where systemd is preferred:
export _SYSTEMCTL_SKIP_REDIRECT=true

if [ -f /etc/rc.d/init.d/functions ]; then
  # shellcheck disable=SC1091
  . /etc/rc.d/init.d/functions
elif [ -f /lib/lsb/init-functions ]; then
  # shellcheck disable=SC1091
  . /lib/lsb/init-functions
fi

if [ -f /etc/sysconfig/consul ]; then
  # shellcheck disable=SC1091
  . /etc/sysconfig/consul
elif [ -f /etc/default/consul ]; then
  # shellcheck disable=SC1091
  . /etc/default/consul
fi

start() {
  if type log_daemon_msg > /dev/null 2>&1; then
    log_daemon_msg "Starting $desc" "$name"
  else
    echo -n $"Starting $name: "
  fi

  ${consul_command} agent \
      ${consul_flags} \
      ${CONSUL_FLAGS_FOR_SERVER} \
      ${CONSUL_FLAGS_FOR_CLIENT} \
      2>&1 >>${consul_logfile} &
  retval=$?

  if type log_end_msg > /dev/null 2>&1; then
    log_end_msg $retval
  elif type success > /dev/null 2>&1; then
    if [ $retval -eq 0 ]; then
      success $"$name startup"
    else
      failure $"$name startup"
    fi
    echo
  fi

  return $retval
}

stop() {
  if type log_daemon_msg > /dev/null 2>&1; then
    log_daemon_msg "Stopping $desc" "$name"
  else
    echo -n $"Stopping $name: "
  fi

  ${consul_command} leave
  retval=$?

  if type log_end_msg > /dev/null 2>&1; then
    log_end_msg $retval
  elif type success > /dev/null 2>&1; then
    if [ $retval -eq 0 ]; then
      success $"$name shutdown"
    else
      failure $"$name shutdown"
    fi
    echo
  fi

  return $retval
}

restart() {
  stop
  start
}

reload() {
  if type log_daemon_msg > /dev/null 2>&1; then
    log_daemon_msg "Reloading $desc" "$name"
  else
    echo -n $"Reloading $name: "
  fi

  ${consul_command} reload
  retval=$?

  if type log_end_msg > /dev/null 2>&1; then
    log_end_msg $retval
  elif type success > /dev/null 2>&1; then
    if [ $retval -eq 0 ]; then
      success $"$name reload"
    else
      failure $"$name reload"
    fi
    echo
  fi

  return $retval
}

status() {
  ${consul_command} info
  retval=$?
  return $retval
}

status_quiet() {
  status > /dev/null 2>&1
}

case "$1" in
  start)
    start
    ;;
  halt|poweroff|reboot|kexec|stop)
    stop
    ;;
  status)
    status
    ;;
  restart)
    restart
    ;;
  reload)
    reload
    ;;
  condrestart)
    status_quiet || exit 0
    restart
    ;;
  *)
    echo "Usage: $name {start|stop|status|reload|restart|condrestart}"
    exit 1
    ;;
esac
exit $?

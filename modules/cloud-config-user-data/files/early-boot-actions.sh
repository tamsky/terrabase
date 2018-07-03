#!/bin/bash
# THIS FILE MANAGED BY TERRAFORM


###### Early boot actions

# This task should move to packer-base image:
# Creating the directory before boot allows journald to persist logs.
# Creating the directory after binary starts does not.
# Restart journald now so we persist logs:
mkdir -v /var/log/journal &&
     [[ $(type systemctl) ]] &&
     systemctl restart systemd-journald.service

# Uncomment if cloud-init modifies /etc/rsyslog.conf
# service rsyslog restart

# Fix DNS:
# Ubuntu needs this:
# http://serverfault.com/questions/737375
[[ -f /etc/resolvconf/update.d/libc ]] && {
    cat >/etc/default/resolvconf <<EOF
TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=n
EOF
    resolvconf -u ;
}

apt-get update || true

REQUIRED_PACKAGES="jq awscli"
type -p apt-get && APT_GET=true
type -p yum && YUM=true
TRY=0
while [[ $TRY -lt 5 ]] ; do
   [[ $APT_GET ]] && apt-get install -y $REQUIRED_PACKAGES && break
   [[ $YUM ]] && yum install -y $REQUIRED_PACKAGES && break
   TRY=$(($TRY + 1))
done

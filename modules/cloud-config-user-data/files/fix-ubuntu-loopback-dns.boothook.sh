#!/bin/bash

set -x
LOCK_FILE=/var/local/${INSTANCE_ID}.boothook.fix-ubuntu-loopback-dns

# implement once-per-instance using hook provided environment var:
# https://cloudinit.readthedocs.io/en/latest/topics/format.html#cloud-boothook
[[ -f ${LOCK_FILE} ]] && exit 0

# Fix DNS as early as we can for Ubuntu, which needs this:
# http://serverfault.com/questions/737375

[[ -f /etc/resolvconf/update.d/libc ]] && {
    cat >/etc/default/resolvconf <<EOF
TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=n
EOF
    resolvconf -u ;
}

# prevent 2nd rodeo
touch -v ${LOCK_FILE}

unset LOCK_FILE
exit 0

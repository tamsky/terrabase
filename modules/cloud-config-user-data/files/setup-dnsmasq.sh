#!/bin/bash

set -x

REQUIRED_PACKAGES="dnsmasq"
type -p apt-get && APT_GET=true
type -p yum && YUM=true
TRY=0
while [[ $TRY -lt 5 ]] ; do
   [[ $APT_GET ]] && apt-get install -y $REQUIRED_PACKAGES && break
   [[ $YUM ]] && yum install -y $REQUIRED_PACKAGES && break
   TRY=$(($TRY + 1))
done

ACTUAL_RESOLV_CONF=$(readlink -f /etc/resolv.conf)
cat >>/etc/default/dnsmasq <<EOF

RESOLV_CONF=${ACTUAL_RESOLV_CONF}
EOF

# install config
# 'local-service' directive would be nice here, but RHEL6's dnsmasq version
# doesn't support it.
cat >/etc/dnsmasq.conf <<EOF
conf-dir=/etc/dnsmasq.d
no-poll
cache-size=65535
# recursors <insert-resolv.conf-value-here>
EOF

# install resolver forwarding
cat >/etc/dnsmasq.d/10-consul.conf <<EOF
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EOF

# activate at boot
chkconfig dnsmasq on || true

# AMZN / Centos needs this, but doesn't harm Ubuntu
cat >/etc/dhcp/dhclient-exit-hooks <<EOF
sed -e 's/^\(search [^ ]\+\).*/\1/' /etc/resolv.conf
EOF

# Start dnsmasq
/etc/init.d/dnsmasq restart

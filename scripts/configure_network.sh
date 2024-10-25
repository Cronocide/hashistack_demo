#!/bin/sh

# WARNING: When executed as a 'shell' directive in the Packer provisioner, this actually runs
# in an sh shell, not a bash shell. Consequently, when any of these commands fail, so does
# the script, and the whole packer build.

# Ensure that this script is only run if root.
CURRENT_SCRIPT="$0"
UID=$(id -u)
[ $UID != 0 ] && echo "$CURRENT_SCRIPT is expected to be run as UID 0, but is run as $UID. Aborting." && return 1

echo 'Configuring Network'

# Remove previous netplan configs and install from them from Packer's files
rm -rf /etc/netplan/* || echo
if [ "$ROLE" = "worker" ]; then
	mv /tmp/netplan/worker.yaml /etc/netplan/50-cloud-init.yaml
	chmod 700 /etc/netplan/50-cloud-init.yaml
fi
if [ "$ROLE" = "server" ]; then
        mv /tmp/netplan/server.yaml /etc/netplan/50-cloud-init.yaml
	chmod 700 /etc/netplan/50-cloud-init.yaml
fi

netplan generate

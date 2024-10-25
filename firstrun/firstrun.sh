#!/bin/bash
# /opt/firstrun.sh

# This script is transferred to the host to be run after the provisioner has
# left. Therefore, it must manage it's own lifecycle. firstrun.service is
# the job that runs this script.

disable_self() {
	# Write firstrun date to prevent running again
	echo $(date) > /etc/.firstrun
	# Disable the systemdjob
	systemctl disable firstrun
	systemctl daemon-reload
	# Delete systemd unit and setup script
	rm /etc/systemd/system/firstrun.service
	rm /opt/firstrun.sh
}

first_run() {
	echo "Now running firstrun scripts. This should never happen again."
	# Set hostname from the VM's first start date
	new_hostname=ubuntu-$(date| md5sum | cut -b 1-8)
	hostnamectl set-hostname $new_hostname
	sed -i "s#ubuntu#$new_hostname#" /etc/hosts
	# Do anything we want to only happen the first time the VM is set up.

	disable_self
}

# Check that /etc/.firstrun exists and run if it does not.
SETUP_USER='packer'
if ! [[ -f /etc/.firstrun ]]; then
	# Only run if setup user does not exist
	id -u $SETUP_USER || first_run
fi

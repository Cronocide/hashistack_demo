#!/bin/sh

# WARNING: When executed as a 'shell' directive in the Packer provisioner, this actually runs
# in an sh shell, not a bash shell. Consequently, when any of these commands fail, so does
# the script, and the whole packer build.

# Ensure that this script is only run if root.
CURRENT_SCRIPT="$0"
UID=$(id -u)
[ $UID != 0 ] && echo "$CURRENT_SCRIPT is expected to be run as UID 0, but is run as $UID. Aborting." && return 1

echo 'Cleaning up...'

# Force a new growroot on next boot
rm -rf /etc/growroot-disabled || echo

# Remove setup user from cloud-init
rm -rf /etc/cloud/cloud.cfg.d/99-installer.cfg || echo
# Disable cloud-init
systemctl disable cloud-init.service || echo
systemctl disable cloud-config.service || echo
systemctl disable cloud-final.service || echo
touch /etc/cloud/cloud-init.disabled

# Verify ownership of home directory
chown -R $USERNAME:$USERNAME /home/$USERNAME/

# Remove setup user (Unless using VirtualBox, which needs the user to shutdown the VM)
if [ -z $(echo "$PACKER_BUILD_PLATFORM" | grep "virtualb") ]; then userdel -rf "$SETUP_USER"; rm /etc/sudoers.d/"$SETUP_USER"; fi
echo 'Setup complete.'

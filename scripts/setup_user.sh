#!/bin/bash

# WARNING: When executed as a 'shell' directive in the Packer provisioner, this actually runs
# in an sh shell, not a bash shell. Consequently, when any of these commands fail, so does
# the script, and the whole packer build.

# Ensure that this script is only run if root.
CURRENT_SCRIPT="$0"
UID=$(id -u)
[ $UID != 0 ] && echo "$CURRENT_SCRIPT is expected to be run as UID 0, but is run as $UID. Aborting." && return 1

echo "Setting up user $USERNAME"

# Install vm guest packages
for i in "qemu-guest-agent open-vm-tools"; do DEBIAN_FRONTEND=noninteractive apt install -y $i || continue; done

# Create user $USERNAME
adduser --disabled-password --gecos "" $USERNAME
adduser $USERNAME sudo
# Setup SSH access
mkdir -p /home/$USERNAME/.ssh/
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh/
echo "$USER_KEY" >> /home/$USERNAME/.ssh/authorized_keys
# Remove sudo password requirement
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USERNAME

# Download Cronocide's Bash Profile
BASH_PROFILE="/home/$USERNAME/.bash_profile"
sudo -u $USERNAME curl -s https://setup.cronocide.com/.bash_profile > "$BASH_PROFILE"
chown $USERNAME:$USERNAME "$BASH_PROFILE"

# Run initial setup for Cronocide's Dotfiles
sudo -u $USERNAME bash "$BASH_PROFILE"
# Install the dotfiles
echo '#!/bin/bash\n'"source $BASH_PROFILE && install_dotfiles" > "/home/$USERNAME/setup_cli.sh"
chmod +x "/home/$USERNAME/setup_cli.sh"
sudo -u $USERNAME bash "/home/$USERNAME/setup_cli.sh"
rm "/home/$USERNAME/setup_cli.sh"

echo "Done setting up user $USERNAME"

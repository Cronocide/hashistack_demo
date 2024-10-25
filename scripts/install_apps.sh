#!/bin/sh

# WARNING: When executed as a 'shell' directive in the Packer provisioner, this actually runs
# in an sh shell, not a bash shell. Consequently, when any of these commands fail, so does
# the script, and the whole packer build.

# Ensure that this script is only run if root.
CURRENT_SCRIPT="$0"
UID=$(id -u)
[ $UID != 0 ] && echo "$CURRENT_SCRIPT is expected to be run as UID 0, but is run as $UID. Aborting." && return 1

echo 'Installing Apps'

# Run system updates.
DEBIAN_FRONTEND=noninteractive apt update && apt upgrade -y

# Ensure apt has HTTPS transport
DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates software-properties-common

# Install helpful command line tools
for i in sudo curl wget md5sum bc screen sed net-tools; do DEBIAN_FRONTEND=noninteractive apt-get install -y $i || continue; done

# Install NFS Support
DEBIAN_FRONTEND=noninteractive apt install -y nfs-common

# Make mountpoint for NFS storage area
mkdir /mnt/storage
chattr +i /mnt/storage

# Add mounting info to /etc/fstab
echo "$NFS_MOUNTS" >> /etc/fstab

# Move firstrun files into place and enable firstrun
mv /tmp/firstrun/firstrun.sh /opt/
mv /tmp/firstrun/firstrun.service /etc/systemd/system/
rm -rf /tmp/firstrun
chmod +x /opt/firstrun.sh
systemctl enable firstrun

# Install Docker Repos
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce

# Install Hashicorp Repos
curl -fsSL https://apt.releases.hashicorp.com/gpg |  gpg --dearmor > /etc/apt/trusted.gpg.d/hashicorp.gpg
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Install Consul
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y consul || continue

# Move Consul files into place and enable Consul
mv /tmp/consul/consul.service /etc/systemd/system/
if [ "$ROLE" = "worker" ]; then
	mv /tmp/consul/client.hcl /etc/consul.d/consul.hcl
fi
if [ "$ROLE" = "server" ]; then
	mv /tmp/consul/server.hcl /etc/consul.d/consul.hcl
	mv /tmp/consul/* /etc/consul.d/
	rm /etc/consul.d/client.hcl
fi
# Make data directory and set ownership
mkdir /var/lib/consul
mkdir /var/consul
chown consul:consul /var/lib/consul
chown consul:consul /var/consul
rm -rf /tmp/consul
systemctl enable consul
# Allow Consul to bind to port 53
setcap 'cap_net_bind_service=+ep' /usr/bin/consul

# If a server, then install keepalived to balance a shared IP address for DNS
if [ "$ROLE" = "server" ]; then
	DEBIAN_FRONTEND=noninteractive apt-get install -y keepalived
	mv /tmp/keepalived/* /etc/keepalived/
	[ -f /etc/keepalived/notify.sh ] && chmod 700 /etc/keepalived/notify.sh && chmod +x /etc/keepalived/notify.sh
	systemctl enable keepalived
fi

# Install Nomad
DEBIAN_FRONTEND=noninteractive apt-get install -y nomad || continue

# Move Nomad files into place and enable Nomad
mv /tmp/nomad/nomad.service /etc/systemd/system/
if [ "$ROLE" = "worker" ]; then
	mv /tmp/nomad/client.hcl /etc/nomad.d/nomad.hcl
fi
if [ "$ROLE" = "server" ]; then
	mv /tmp/nomad/server.hcl /etc/nomad.d/nomad.hcl
fi
# Copy Nomad jobs over
mkdir /etc/nomad.d/jobs
cp -r /tmp/nomad/jobs/* /etc/nomad.d/jobs
chown -R nomad:nomad /etc/nomad.d/jobs
# Make data directory and set ownership
mkdir /var/lib/nomad
chown nomad:nomad /var/lib/nomad
rm -rf /tmp/nomad
systemctl enable nomad

# Install Optional Nomad Plugins

# Install CNI networking plugins
CNI_NETWORKING_PLUGINS_URL=$(curl -s -L "https://api.github.com/repos/containernetworking/plugins/releases/latest" | grep browser_download_url | grep linux | grep -v sha1 | grep -v sha512 | grep -v sha256 | grep -v md5 | grep "$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)" | cut -d '"' -f 4)
[ -z "$CNI_NETWORKING_PLUGINS_URL" ] && echo "Unable to determine CNI_NETWORKING_PLUGINS_URL."
curl -s -L -o cni-plugins.tgz "$CNI_NETWORKING_PLUGINS_URL"
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf cni-plugins.tgz
rm cni-plugins.tgz
# Install containerd plugin
CONTAINERD_PLUGIN_URL=$(curl -s -L "https://api.github.com/repos/Roblox/nomad-driver-containerd/releases/latest" | grep browser_download_url | grep $( [ $(uname -m) = aarch64 ] && echo arm64 || echo '-v arm64') | cut -d '"' -f 4)
[ -z "$CONTAINERD_PLUGIN_URL" ] && echo "Unable to determine CONTAINERD_PLUGIN_URL."
curl -s -L -o containerd-driver "$CONTAINERD_PLUGIN_URL"
chmod +x containerd-driver
mkdir -p /opt/nomad/plugins
mv containerd-driver /opt/nomad/plugins/

# Install systemd-nspawn plugin
DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go
SYSTEMD_NSPAWN_PLUGINS_URL=$(curl -s -L "https://api.github.com/repos/JanMa/nomad-driver-nspawn/releases/latest" | grep browser_download_url | grep zip | cut -d '"' -f 4)
[ -z "$SYSTEMD_NSPAWN_PLUGINS_URL" ] && echo "Unable to determine SYSTEMD_NSPAWN_PLUGINS_URL."
curl -s -L -o nomad-driver-nspawn.zip "$SYSTEMD_NSPAWN_PLUGINS_URL"
gunzip -S .zip nomad-driver-nspawn.zip 2>&1
rm nomad-driver-nspawn.zip || echo
chmod +x nomad-driver-nspawn
mv nomad-driver-nspawn /opt/nomad/plugins/
# Install USB plugin
USB_PLUGIN_URL=$(curl -fsL https://gitlab.com/api/v4/projects/23395095/releases/permalink/latest | sed "s#.*\(https://gitlab.com/api/v4/projects/23395095/packages/generic/nomad-usb-device-plugin/[0-9\.]*/nomad-usb-device-plugin-linux-$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)-[0-9\.]*\)\",.*#\1#")
curl -s -L -o nomad-usb-device-plugin "$USB_PLUGIN_URL"
chmod +x nomad-usb-device-plugin
mv nomad-usb-device-plugin /opt/nomad/plugins/
# Install nvidia plugin
curl -s -L -o nomad-nvidia-plugin.zip https://releases.hashicorp.com/nomad-device-nvidia/1.0.0/nomad-device-nvidia_1.0.0_linux_$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64).zip
gunzip -S .zip nomad-nvidia-plugin.zip 2>&1
rm nomad-nvidia-plugin.zip || echo
chmod +x nomad-nvidia-plugin
mv nomad-nvidia-plugin /opt/nomad/plugins/

# Install CSI storage plugins
# SCSI Support
DEBIAN_FRONTEND=noninteractive apt-get install -y open-iscsi lsscsi sg3-utils multipath-tools scsitools
cat <<EOF > /etc/multipath.conf
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF
systemctl enable multipath-tools.service || echo
systemctl enable open-iscsi.service || echo

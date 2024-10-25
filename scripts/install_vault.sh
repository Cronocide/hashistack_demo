#!/bin/sh

# WARNING: When executed as a 'shell' directive in the Packer provisioner, this actually runs
# in an sh shell, not a bash shell. Consequently, when any of these commands fail, so does
# the script, and the whole packer build.

# Ensure that this script is only run if root.
CURRENT_SCRIPT="$0"
UID=$(id -u)
[ $UID != 0 ] && echo "$CURRENT_SCRIPT is expected to be run as UID 0, but is run as $UID. Aborting." && return 1

# Skip the vault install if it's a worker, and just use the vault server.
[ "$ROLE" = "worker" ] && exit 0

echo 'Installing Vault'

# Verify and install dependencies
[ ! -d /tmp/vault/ ] && error "Missing required folder /tmp/vault, not installing vault." && return 1
DEBIAN_FRONTEND=noninteractive apt-get install -y openssl golang-go git
# Install hashicorp repos if not installed
if [ ! -f /etc/apt/trusted.gpg.d/hashicorp.gpg ]; then
	curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/hashicorp.gpg
	apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
	apt-get update
fi
DEBIAN_FRONTEND=noninteractive apt-get install -y vault
# Enable mlock for Vault
setcap cap_ipc_lock=+ep $(readlink -f $(which vault))
# Move Vault files into place and enable Vault
mv /tmp/vault/vault.service /etc/systemd/system/
mv /tmp/vault/vault-unseal.service /etc/systemd/system/
mv /tmp/vault/* /etc/vault.d/
mkdir -p /var/lib/vault
chown vault:vault /var/lib/vault
# Replace default TLS cert with one that signs for vault.service.consul
openssl req -x509 -newkey rsa:4096 -keyout /opt/vault/tls/tls.key -out /opt/vault/tls/tls.pem -days 5478 -nodes -subj "/CN=Vault/O=Hashicorp" -addext "subjectAltName=IP:127.0.0.1,DNS:vault.service.consul"
chown -R vault:vault /opt/vault/tls/
# Cleanup
rm -rf /tmp/vault
systemctl enable vault
systemctl enable vault-unseal
export VAULT_CACERT=/opt/vault/tls/tls.pem
# Install plugins
git clone https://github.com/1Password/vault-plugin-secrets-onepassword
cd vault-plugin-secrets-onepassword
go build -o vault/plugins/op-connect .
cd ../
mkdir -p /etc/vault.d/plugins
mv vault-plugin-secrets-onepassword/vault/plugins/* /etc/vault.d/plugins
chown -R vault:vault /etc/vault.d/plugins
rm -rf vault-plugin-secrets-onepassword
# Bootstrap the vault server.
systemctl start vault
sleep 10
/etc/vault.d/bootstrap.sh

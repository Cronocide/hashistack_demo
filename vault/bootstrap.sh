#!/bin/bash

# A quick Vault bootstrap for homelab environments.

# Suppress vault address and TLS warnings by setting the VAULT_ADDR and VAULT_CACERT
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_CACERT="/opt/vault/tls/tls.pem"
# Initialize Vault with a file backend. This is usually fine as long as you trust the server vault is running on.
init_result=$(vault operator init -n 1 -t 1 -ca-cert /opt/vault/tls/tls.pem -format=json)
# Get the unseal key (needed to unseal the vault for use)
unseal_key=$(echo "$init_result" | jq -r '.unseal_keys_b64[0]')
[ -z "$unseal_key" ] && echo "Unable to initizlize vault." && exit 1
# Get the root login token (needed to log in and make changes to vault)
root_token=$(echo "$init_result" | jq -r '.root_token')
echo -e "ROOT TOKEN IS \033[1;31;44m$root_token\033[00m"
# Unseal the vault
echo -e "UNSEAL KEY IS \033[1;31;44m$unseal_key\033[00m"
vault operator unseal "$unseal_key"
# Write the unseal token to disk for auto-unsealing
echo "ROOT_TOKEN=$root_token" > /etc/default/vault
echo "UNSEAL_KEY=$unseal_key" >> /etc/default/vault
echo "VAULT_ADDR=https://127.0.0.1:8200" >> /etc/default/vault
echo "VAULT_CACERT=/opt/vault/tls/tls.pem" >> /etc/default/vault
# Login as root
vault login "$root_token"
# Install and configure the 1Password plugin for Vault
op_connect_shasum=$(shasum -a 256 /etc/vault.d/plugins/op-connect | cut -d " " -f1)
vault write sys/plugins/catalog/secret/op-connect sha_256="$op_connect_shasum" command="op-connect"
vault secrets enable --plugin-name='op-connect' --path="op" plugin
# Write the 1Password API Token to Vault
vault write op/config @/etc/vault.d/opconfig.json

# Enable jwt authentication for Nomad
vault auth enable -path 'jwt-nomad' 'jwt'
# Enable the traditional KV store for vault
vault secrets enable -version '2' 'kv'
# Write our config for nomad-jwt authentication
vault write auth/jwt-nomad/config '@/etc/vault.d/vault-auth-method-jwt-nomad.json'
# Write our config for Nomad jobs
vault write auth/jwt-nomad/role/nomad-jobs '@/etc/vault.d/vault-role-for-nomad-jobs.json'
# Get our Nomad auth method's unique ID to create an access policy
auth_methods=$(vault auth list -format=json)
accessor=$(echo "$auth_methods" | jq -r '."jwt-nomad/".accessor')
# Insert our accessor into our access policy
sed -i "s#AUTH_METHOD_ACCESSOR#$accessor#g" /etc/vault.d/vault-policy-for-nomad-jobs.hcl
# Write our policy to vault
vault policy write 'nomad-jobs' '/etc/vault.d/vault-policy-for-nomad-jobs.hcl'

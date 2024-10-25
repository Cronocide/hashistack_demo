<div align="center"><img width="20%"src="https://www.fortunefrenzy.co.uk/wp-content/uploads/2017/02/Level-Up-icon-1024x1024.png"></div>
# Level Up Your Homelab Without Kubernetes
## Saintcon 2024 Presentation

Demo code for the presentation on Packer, Consul, Nomad, and Vault.

[Slides](https://slides.com/d/RpyEEDY)

---

### Building with Packer

To build the VMs in the demo code you'll need to install Packer. Once you've installed packer, initialize the packer repo with

```
packer init packerfiles/{proxmox,virtualbox}.pkr.hcl
```

_(For proxmox or virtualbox builds)_.

[![Running Packer](https://asciinema.org/a/jxdC4Tut7aVehT83AA03N9wrf.svg)](https://asciinema.org/a/jxdC4Tut7aVehT83AA03N9wrf/iframe?loop=true&speed=8&theme=asciinema&rows=37&autoplay=1)


### Platform

By submitting a `ROLE`  variable you can install the server or worker files for the cluster. When the server files are installed, additional platform tools are installed to make life a little easier:

* `keepalived` is installed to load balance the Consul DNS server address. If Consul does not listen on this shared address (`10.10.64.253`), restart Consul to bind to the `keepalived` IP address.
* `netplan` is configured to use Consul as the DNS server

### Consul

Consul is configured to use a default upstream resolver of `10.10.64.1`. You will need to change this to match your environment.
The [Consul service files](consul/truenas.hcl) for TrueNAS and Proxmox also have static IPs that will need to be changed depending on your environment.
Consul is not configured with ACLs, so anyone on your network can control it. I recommend using Consul ACLs with an identity provider of your choice.

### Nomad

Nomad is not configured with ACLs, so anyone on your network can control it. I recommend using Consul ACLs with an identity provider of your choice.


### Vault

The included [bootstrap.sh](vault/bootstrap.sh) automatically bootstraps the Vault cluster with a single cluster leader and a single vault unseal key.
It saves the root token (needed to make changes to Vault) as well as the unseal key to `/etc/default/vault`.
A service called `vault-unseal` is provided to automatically unseal the vault at startup. Whenever Vault restarts, it needs to be unsealed before use (even for plugins such as 1Password).
The included policy for 1Password only allows access to items in your 1Password account whose name matches the nomad job ID. See [vault-policy-for-nomad-jobs.hcl](vault/vault-policy-for-nomad-jobs.hcl).

### 1Password

You will need the `opconfig.json` installed on the vault server and `1password-credentials.json` installed in your 1Password-Connect job's storage for the 1Password vault plugin to start.



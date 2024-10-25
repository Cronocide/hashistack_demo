# This tells Packer that we need the Proxmox plugin for this file to build.
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# This will tell our scripts whether to install the server or worker config files from this repo.
variable "ROLE" {
  type    = string
  default = "worker"
}

# This string will be added to /etc/fstab to mount shared storage on the host.
variable "NFS_MOUNTS" {
  type    = string
  default = "10.10.64.53:/mnt/Media/Storage /mnt/storage  nfs      hard,intr,tcp,user,relatime,timeo=120,retrans=10,local_lock=posix,exec    0       0"
}

# This is the name of the user that packer will use to connect to the VM after the OS is installed. It matches the cloudinit config that is passed to the VM on boot.
variable "SETUP_USER" {
  type    = string
  default = "packer"
}

# The name of the user to configure on the new host.
variable "USERNAME" {
  type    = string
  default = "cronocide"
}

# The SSH key to install for the user on the new host.
variable "USER_KEY" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCv3IUdl8TfJcifthxMmPZ6NOqDbWupzDaS6wkUK+Qa2Qe4XoGeSGWUuR/bJIndqeRwZ3/CTwnp2/rUpMTidjsA8WH05O7D0lA+g+6EKlaCVYdgheBjMi/LK18It5aHgetypia9SwvdpuKxQT61C4bk4RJ0lenPb6rbhAeQjqORXY0NnoFoZHUGPPfulWhwkb6naGzCurAFMEcffW4L2kAujEcAsW46mVNaMWT2XqKyV5SVNOGP+olGAZWN4NPQo8sCE5kHM2ksyMc9XoVZ3mCs6VKWFZiBdQLfZUd0A5iuljIW3yxBqsJdbAYT/k4O5oMyS5P0TvoTn57dDC+Gl9PZ\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDNrlWo2OE9mtppyv11O1kLesuNdE0ngMB4o026eICgyf+ZtUcG37Tyl3VHIkjTLvANP9KEIzl2dwPDI7E7ArSd9CefLI1w9jr764OSwVoUA+YFmEi+iJ+BFJ6Kmn9p9jtszPAFkKdVKgd+hMsolr2h7p8RS+0aJuJATnfg5vQTzY2U+6SalnXsOX7QJ64/a/FnOAmSo6xOqWssu0Lxb/WjCr7P6MxHK1xWI9T/3ZgSExZQ3e/wWt+yzTBE0pP2phqcKsnZyJoHWMRv8B+csOnQlE7moKkfOFwaVmT+/oLKvcWCKXa6Vv9l5cJnCuWaa3AW8V3nHhxMcavf6CLYVY968CiBmOrZP87pUcI237MVWYjmy/NfJonaXC8JaIDRYj5ogZfrxzN4PjayWyCUh62D3JBpFYn9D08F32bgHbZ0aMwCbUIWprOLAIN6GEskNO39ZhOOLXDk+6Lccp6qerfwSRrf3qNhQGqT4VNVZQa0iixvlUtEvNWBep1jCHBr+jc="
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "proxmox-iso" "saintcon-packer-demo" {
  bios         = "ovmf"
  # The boot command is what is typed in using a virtual keyboard when the machine is first booted. Usually used to configure the startup mode for the VM.
  boot_command = [
                  "<wait><shift><wait><shift><wait><shift><shift><shift><wait><shift>",
                  "<wait>e<down><down><down><down><left><bs><bs><bs> ",
                  "autoinstall ds='nocloud;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ---<wait>",
                  "<f10><wait>"
                 ]
  boot_wait    = "10s"
  communicator = "ssh"
  sockets      = "1"
  cores        = "4"
  cpu_type     = "host"
  efi_config {
      efi_storage_pool = "local-zfs"
  }
  boot_iso {
      # Use these to download the ISO to Proxmox's local ISO store
#      iso_url              = "https://releases.ubuntu.com/24.04/ubuntu-24.04.1-live-server-amd64.iso"
#      iso_storage_pool     = "local"
      # Use this to tell Packer to use the existing ISO in Proxmox's local ISO store
      iso_file             = "local:iso/ubuntu-24.04.1-live-server-amd64.iso"
      iso_checksum         = "e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9"
      type                 = "ide"
      unmount              = true
  }
  # Use the cloudinit directory to provide cloudinit files over a simple HTTP server for the VM to retrieve.
  http_directory           = "./cloudinit"
  insecure_skip_tls_verify = true
  memory                 = "16384"
  node                   = "saintcon-demo"
  proxmox_url            = "https://10.10.64.205:8006/api2/json"
  qemu_agent             = true
  ssh_username           = "${var.SETUP_USER}"
  ssh_password           = "${var.SETUP_USER}"
  ssh_timeout            = "60m"
  ssh_read_write_timeout = "30m"
  tags                   = "${var.ROLE}"
  template_description   = "# ${var.ROLE} VM\n### Built by Packer\n\n| | |\n|--------------|-----------|\n| **User** | ${var.USERNAME}"
  template_name          = "${var.ROLE}-${local.timestamp}"
  username               = "packer@pam!build"
  token                  = "c3f30982-42c2-4dae-a1ca-ef788eba25bb"
  vm_name                = "${var.ROLE}-${local.timestamp}"
  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "e1000"
  }
  disks {
    disk_size         = "32G"
    format            = "raw"
    storage_pool      = "local-zfs"
    type              = "ide"
  }
}

build {
  sources = ["source.proxmox-iso.saintcon-packer-demo"]

  # Copy over Consul config files.
  provisioner "file" {
    destination = "/tmp"
    source      = "consul"
  }

  # Copy over Nomad config files.
  provisioner "file" {
    destination = "/tmp"
    source      = "nomad"
  }

  # Copy over Vault config files.
  provisioner "file" {
    destination = "/tmp"
    source      = "vault"
  }

  # Copy over Keepalived config files.
  provisioner "file" {
    destination = "/tmp"
    source      = "keepalived"
  }

  # Copy over Netplan config files.
  provisioner "file" {
    destination = "/tmp"
    source      = "netplan"
  }

  # Copy over files for setting up the 'firstrun' service
  provisioner "file" {
    destination = "/tmp"
    source      = "firstrun"
  }


  provisioner "shell" {
    # Environment variables with which to run scripts. 
    environment_vars  = ["ROLE=${var.ROLE}", "NFS_MOUNTS=${var.NFS_MOUNTS}", "USERNAME=${var.USERNAME}", "USER_KEY=${var.USER_KEY}", "SETUP_USER=${var.SETUP_USER}"]
    # Run all commands using the sudo privileges of the SETUP_USER (packer).
    execute_command   = "echo '${var.SETUP_USER}' | {{ .Vars }} sudo --stdin --preserve-env sh -eux '{{ .Path }}'"
    # Allow the host to become disconnected during the setup process without failing. Useful for restarting network services on the host during setup.
    expect_disconnect = true
    # Scripts to run over SSH on the new host.
    scripts          = ["scripts/setup_user.sh", "scripts/install_apps.sh", "scripts/install_vault.sh", "scripts/configure_network.sh", "scripts/cleanup.sh"]
  }

}

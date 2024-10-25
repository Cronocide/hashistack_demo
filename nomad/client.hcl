data_dir = "/opt/nomad"
datacenter = "saintcon"
leave_on_terminate = true
leave_on_interrupt = true
ui {
  enabled = false
}
client {
  enabled = true
  servers = ["nomad.service.consul"]
  no_host_uuid = true
  drain_on_shutdown {
    deadline = "2m"
    force = true
    ignore_system_jobs = false
  }
  template {
    vault_retry {
      attempts = 0
      backoff = "10s"
      max_backoff = "1m"
    }
  }
  host_volume {
    "shared" = {
      path = "/mnt/storage"
      read_only = false
    }
  }
  network_interface = "ens18"
  host_network {
    "default" = {
      cidr = "10.10.64.0/24"
    }
  }
}

"plugin" = {
  "docker" = {
    pull_activity_timeout = "15m"
    infra_image_pull_timeout = "15m"
    config {
      volumes = {
        enabled = true
      }
      # If we allow running privileged commands, we might as well allow privileged capabilities.
      allow_privileged = true
      allow_caps = ["audit_write", "chown", "dac_override", "fowner", "fsetid", "kill", "mknod", "net_bind_service", "setfcap", "setgid", "setpcap", "setuid", "sys_chroot", "sys_module", "net_admin", "net_raw", "net_bind_service"]
      extra_labels = ["job_name", "job_id", "task_group_name", "task_name"]
    }
  }
  "containerd-driver" = {
    config = {
      enabled = true
      containerd_runtime = "io.containerd.runc.v2"
    }
  }
  "nspawn" = {
    config = {
      enabled = true
    }
  }
  "exec" = {
    config = {
      allow_caps = ["all"]
    }
  }
  "raw_exec" = {
    config {
      enabled = false
    }
  }
}

plugin "nomad-usb-device-plugin" {
  config {
    enabled = true
    fingerprint_period = "15s"
    mount_dev_nodes = true
    included_vendor_ids = []
    included_product_ids = []
    excluded_vendor_ids = []
    excluded_product_ids = []
  }
}

plugin "nspawn" {
  config = {
    enabled = true
  }
}
consul {
  address = "127.0.0.1:8500"
  server_service_name = "nomad-{{.Name}}"
}

vault {
  address = "https://vault.service.consul:8200"
  enabled = true
  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
  tls_skip_verify = true
  task_token_ttl = "1h"
}

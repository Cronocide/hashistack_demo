# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
datacenter = "saintcon"

server {
  enabled = true
  bootstrap_expect = 1
  # Cluster encryption key
  # You can generate this with `nomad operator gossip keyring generate`
  # or `openssl rand 32 | base64`
  encrypt = "DicA8PGid3L7JDyHaSFYR/NEMLHu6tqNwR3N6WQgja4="
}

client {
  enabled = false
  servers = ["127.0.0.1"]
}

consul {
  address = "127.0.0.1:8500"
  client_service_name = "nomad-http"
  tags = ["http","management"]
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
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

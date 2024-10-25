ui = true
storage "file" {
  path = "/opt/vault/data"
}
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/tls.pem"
  tls_key_file  = "/opt/vault/tls/tls.key"
}
plugin_directory = "/etc/vault.d/plugins"

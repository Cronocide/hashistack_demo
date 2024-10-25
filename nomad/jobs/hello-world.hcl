job "hello-world" {
  type = "batch"
  group "primary" {
    vault {}
    task "hello-world" {
      driver = "docker"
      config {
        image = "busybox:latest"
        command = "sh"
        args = ["/local/entrypoint.sh"]
      }
      template {
        destination = "/local/entrypoint.sh"
        data =<<EOF
#!/bin/sh
{{with secret "op/vaults/saintcon/items/hello-world"}}
echo "The username is {{.Data.username}} and the password is {{.Data.password}}"
{{end}}
EOF
      }
      resources {
        memory = 128
      }
    }
  }
}

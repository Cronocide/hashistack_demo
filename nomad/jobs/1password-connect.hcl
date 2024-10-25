job "1password-connect" {
	datacenters = ["saintcon"]
	priority = 100
	# Take a look at https://github.com/1Password/connect/blob/main/examples/docker/compose/docker-compose.yaml
	group "primary" {
		network {
			# Static bacuse Vault needs to talk to them
			port "http-api" {
				static = "8482"
			}
			port "http-sync" {
				static = "8481"
			}
			port "bus-api" {
				to = "6522"
			}
			port "bus-sync" {
				to = "6523"
			}
		}
		service {
			name = "${NOMAD_JOB_NAME}"
			tags = ["http","internal","management"]
			port = "http-api"
			check {
				name = "Service Bound"
				type = "tcp"
				interval = "10s"
				timeout = "5s"
			}
			check {
				name = "Service Ready"
				type = "http"
				interval = "10s"
				timeout = "5s"
				path = "/health"
				on_update = "ignore"
			}
                }
                volume "app" {
                        type = "csi"
                        source = "1password"
                        read_only = true
                        attachment_mode = "file-system"
			access_mode = "multi-node-single-writer"
                        per_alloc = false
                }
		task "connect-api" {
			driver = "docker"
			config {
				image = "1password/connect-api:latest"
				image_pull_timeout = "15m"
				ports = ["http-api","bus-api"]
				mount {
					type = "bind"
					target = "/home/opuser/.op/data"
					source = "..${NOMAD_ALLOC_DIR}/data/"
					readonly = false
					bind_options {
						propagation = "rshared"
					}
				}
			}
			volume_mount {
				volume = "app"
                                destination = "/data"
				read_only = true
                        }
			env {
				USER_UID = 999
				USER_GID = 999
				OP_SESSION = "/data/1password-credentials.json"
				OP_HTTP_PORT = 8482
				OP_BUS_PORT = 6522
				OP_BUS_PEERS = "${NOMAD_HOST_ADDR_bus-sync}"
			}
			restart {
				attempts = 3
				delay    = "30s"
				mode     = "delay"
			}
		}
		task "connect-sync" {
			driver = "docker"
			config {
				image = "1password/connect-sync:latest"
				image_pull_timeout = "15m"
				ports = ["http-sync","bus-sync"]
				mount {
					type = "bind"
					target = "/home/opuser/.op/data"
					source = "..${NOMAD_ALLOC_DIR}/data"
					readonly = false
					bind_options {
						propagation = "rshared"
					}
				}
			}
			volume_mount {
				volume = "app"
                                destination = "/data"
				read_only = false
			}
			env {
				USER_UID = 999
				USER_GID = 999
				OP_SESSION = "/data/1password-credentials.json"
				OP_HTTP_PORT = 8481
				OP_BUS_PORT = 6523
                                OP_BUS_PEERS = "${NOMAD_HOST_ADDR_bus-api}"
			}
			restart {
				attempts = 3
				delay    = "30s"
				mode     = "delay"
			}
		}
	}
}

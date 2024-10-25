job "jenkins" {
	datacenters = ["saintcon"]
	priority = 70
	group "primary" {
		network {
			port "http" {
				static = "8080"
				host_network = "default"
			}
			port "jenkins-internal" {
				static = "50000"
				host_network = "default"
			}
		}
                volume "app" {
                        type = "csi"
                        source = "jenkins"
                        read_only = false
                        attachment_mode = "file-system"
                        access_mode = "single-node-writer"
                        per_alloc = false
                }
		service {
			name = "${NOMAD_JOB_NAME}-http"
			tags = ["http"]
			port = "http"
			meta {
				name = "Jenkins"
				description = "Build great things at any scale"
				icon = "https://raw.githubusercontent.com/github/explore/4546263bd5739353083c33dada43f8f31e7d1fd6/topics/jenkins/jenkins.png"
				category = "Development"
				groups = "Developers"
			}
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
				path = "/"
				on_update = "ignore"
			}
                }
		task "server" {
			driver = "docker"
			config {
				image = "jenkins/jenkins:latest"
				image_pull_timeout = "15m"
				ports = ["http","jenkins-internal"]
			}
			volume_mount {
				volume = "app"
                                destination = "/var/jenkins_home"
                        }
			env {
				UID=1001
				GID=1001
			}
			resources {
				cores = 4
				memory = 8096
			}
			restart {
				attempts = 3
				delay    = "30s"
				mode     = "delay"
			}
		}
	}
}

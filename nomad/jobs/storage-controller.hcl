job "storage-controller" {
	datacenters = ["saintcon"]
	type = "service"
	priority = 100
	group "truenas-csi" {
		network {
			mode = "bridge"	
			port "grpc" {
				static = 9000
				to = 9000
			}
		}
		task "controller" {
			driver = "docker"
			config {
				image = "democraticcsi/democratic-csi:latest"
				image_pull_timeout = "15m"
				ports = ["grpc"]
				args = [
				"--csi-version=1.5.0",
				"--csi-name=truenas",
				"--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
				"--log-level=debug",
				"--csi-mode=controller",
				"--server-socket=/truenas-data/csi.sock",
				"--server-address=0.0.0.0",
				"--server-port=9000",
				]
				privileged = true
                                volumes = [
                                        "/:/host",
                                        "/etc/iscsi:/etc/iscsi",
                                        "/var/lib/iscsi:/var/lib/iscsi",
                                        "/run/udev:/run/udev"
                                ]
			}
			csi_plugin {
				id = "truenas"
				type = "controller"
				mount_dir = "/truenas-data"
			}
			template {
				destination = "${NOMAD_TASK_DIR}/driver-config-file.yaml"
				data = <<EOF
# Commented example at https://github.com/democratic-csi/democratic-csi/blob/master/docs/nomad.md
driver: freenas-iscsi
instance_id:
httpConnection:
  protocol: http
  host: truenas.service.consul
  port: 80
  apiKey: 1-wczFBwPgxxPexzzmhvqHIhef4uphDeHns4Z0F71gVBitfhkoOlz6QEOCLhgJ9Cmz
  username: csi
  allowInsecure: true
sshConnection:
  host: truenas.service.consul
  port: 22
  username: csi
  password: "hcz2kcr9rkvYME6upy"
  privateKey:
zfs:
  cli:
    sudoEnabled: true
  datasetParentName: Media/AppVolumes
  detachedSnapshotsDatasetParentName: Media/AppVolumeSnapshots
  zvolCompression:
  zvolDedup:
  zvolEnableReservation: false
  zvolBlocksize:
iscsi:
  targetPortal: "truenas.service.consul:3260"
  targetPortals: []
  interface:
  namePrefix:
  nameSuffix: 
  targetGroups:
    - targetGroupPortalGroup: 1
      targetGroupInitiatorGroup: 1
      targetGroupAuthType: None
      targetGroupAuthGroup:

  extentInsecureTpc: true
  extentXenCompat: false
  extentDisablePhysicalBlocksize: true
  extentBlocksize: 512
  extentRpm: "SSD"
  extentAvailThreshold: 0
EOF
			}
			resources {
				cpu	= 300
				memory = 100
			}
		}
		task "sudopasswd-fixer" {
			driver = "docker"
			config {
				image_pull_timeout = "15m"
				image = "ghcr.io/cronocide/ssh-docker:latest"
				command = "sh"
				args = [ "/local/check.sh" ]
			}
			template {
				destination = "/local/check.sh"
				data = <<EOF
#!/bin/sh
sshpass -e ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PubKeyAuthentication=no -o PreferredAuthentications=password -l csi truenas.service.consul "echo -e 'hcz2kcr9rkvYME6upy' | sudo -S echo -n; echo -n 's#csi ALL=(ALL) ALL#csi ALL=(ALL) NOPASSWD:ALL#' | sudo -S EDITOR='sed -f- -i' visudo && echo 'success' 1>&2"
EOF
			}
			env {
				SSHPASS = "hcz2kcr9rkvYME6upy"
			}
			lifecycle {
				hook = "prestart"
				sidecar = false
			}
		}
	}
}



job "storage-node" {
	datacenters = ["saintcon"]
	type = "system"
	priority = 100
	group "csi-providers" {
		task "node" {
			driver = "docker"
			config {
				image = "democraticcsi/democratic-csi:latest"
				image_pull_timeout = "15m"
				ipc_mode = "host"
				network_mode = "host"
				args = [
				"--csi-version=1.5.0",
				"--csi-name=truenas",
				"--driver-config-file=${NOMAD_TASK_DIR}/driver-config-file.yaml",
				"--log-level=debug",
				"--csi-mode=node",
				"--server-socket=/csi-data/csi.sock",
				]
				privileged = true
				volumes = [
					"/:/host",
					"/etc/iscsi:/etc/iscsi",
					"/var/lib/iscsi:/var/lib/iscsi",
					# See https://github.com/democratic-csi/democratic-csi/issues/215
					"/run/udev:/run/udev",
					"/sys:/sys"
				]
			}
			csi_plugin {
				id = "truenas"
				type = "node"
				mount_dir = "/csi-data"
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
				cpu = 300
				memory = 100
			}
		}
	}
}

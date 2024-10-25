service {
	name = "proxmox"
	tags = ["management","https"]
	address = "10.10.64.205"
	port = 8006
	meta = {
		groups = "Admins"
		name = "ProxMox"
		description = "Hyper-converged infrastructure hypervisor"
		category = "Administration"
		icon = "https://profesorweb.es/wp-content/uploads/2019/12/proxmox_logo-768x768.jpeg"
	}
	check {
		interval = "1m"
		failures_before_critical = 1
		http = "https://10.10.64.205:8006"
		tls_skip_verify = true
	}
}

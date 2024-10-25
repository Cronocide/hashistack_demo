service {
	name = "truenas"
	tags = ["management","https"]
	address = "10.10.64.53"
	port = 443
	meta = {
		groups = "Admins"
		name = "TrueNAS"
		description = "A storage platform that offers solutions for various storage needs"
		category = "Administration"
		icon = "https://www.truenas.com/wp-content/uploads/2020/07/logo-TrueNAS-Core_119b-compressor.png"
	}
	check {
		interval = "1m"
		failures_before_critical = 1
		http = "https://10.10.64.53:443"
		tls_skip_verify = true
	}
}

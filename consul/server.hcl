bootstrap = true
server = true
datacenter = "saintcon"
data_dir = "/var/lib/consul"
# Cluster encryption key
# You can generate this with `nomad operator gossip keyring generate`
# or `openssl rand 32 | base64`
encrypt = "mkZ/Pi11/mYO7vhk01XR2RT+6knV1BjP54rj72BQmCg=",
ui_config {
	enabled = true
}
addresses {
	# Bind only to our interfaces that aren't internal (like docker or localhost) and include any floating IPs
	dns = "{{range GetAllInterfaces | include \"name\" \"^ens\" | include \"flags\" \"forwardable|up\" | include \"type\" \"IPv4\" }}{{. | attr \"address\" }} {{end}}",
	http = "0.0.0.0"
}
ports {
	dns = 53
}
dns_config = {
	allow_stale = false
}
# IF it's not a consul address, try the router's DNS.
recursors = [ "10.10.64.1" ]
# Make sure that we don't bind on the Docker Network IP
bind_addr = "{{ GetPrivateInterfaces | exclude \"network\" \"172.17.0.1/16\" | attr \"address\" }}"

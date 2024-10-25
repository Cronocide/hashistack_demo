server = false
datacenter = "saintcon"
data_dir = "/var/consul"
encrypt = "mkZ/Pi11/mYO7vhk01XR2RT+6knV1BjP54rj72BQmCg="
log_level = "INFO"
enable_syslog = true
leave_on_terminate = true
recursors = ["consul.service.consul"]
retry_join = [ "consul.service.consul" ]
bind_addr = "{{ GetPrivateInterfaces | exclude \"network\" \"172.17.0.1/16\" | attr \"address\" }}"

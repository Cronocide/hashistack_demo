#!/usr/bin/env bash
# Keepalived Notify Script
# See https://docs.oracle.com/en/operating-systems/oracle-linux/6/admin/section_hxz_zdw_pr.html
# Set to the end state of the transition: BACKUP, FAULT, or MASTER.
ENDSTATE=$3
# Set to the name of the vrrp_instance or vrrp_sync_group.
NAME=$2
# Set to INSTANCE or GROUP, depending on whether Keepalived invoked the program from vrrp_instance or vrrp_sync_group.
TYPE=$1

case $ENDSTATE in
	'BACKUP') # Perform action for transition to BACKUP state
		exit 0;;
	'FAULT')  # Perform action for transition to FAULT state
		exit 0;;
	'MASTER') # Perform action for transition to MASTER state
		service consul restart
		exit 0;;
	*) # Unknown parameters
		echo "Unknown state ${ENDSTATE} for VRRP ${TYPE} ${NAME}";
		exit 1;;
esac

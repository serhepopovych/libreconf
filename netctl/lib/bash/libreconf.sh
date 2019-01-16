#!/bin/bash

[ -z "$__included_libnetctl" ] || return 0
declare -r __included_libnetctl=1

# External tool dependencies, MUST always be defined,
# even if empty (e.g.: declare -a crt1_request_tools_list=())
declare -a crt1_request_tools_list=(
	'sed'		# sed(1)
	'cat'		# cat(1)
	'zcat'		# zcat(1)
	'uname'		# uname(1)
)

# Source startup code
. /netctl/lib/bash/crt1.sh

# Source functions libraries
. /netctl/lib/bash/libfile.sh
. /netctl/lib/bash/liblog.sh
. /netctl/lib/bash/libprocess.sh

################################################################################
# Global options/vars                                                          #
################################################################################

##
## Helpers
##

# Usage: nctl_begin_msg
nctl_begin_msg()
{
	nctl_log_msg '-- %s reconfiguration started --\n' "${NCTL_SUBSYS_NAME#re}"
}
declare -fr nctl_begin_msg

# Usage: nctl_end_msg
nctl_end_msg()
{
	nctl_log_msg '-- %s reconfiguration finished --\n' "${NCTL_SUBSYS_NAME#re}"
}
declare -fr nctl_end_msg

################################################################################
# Load configuration/initialication                                            #
################################################################################

# Source global netctl configuration
nctl_SourceIfNotEmpty "$NCTL_PREFIX/etc/reconf.conf"

# Source local $program_invocation_short_name configuration
nctl_SourceIfNotEmpty "$NCTL_PREFIX/etc/$program_invocation_short_name.conf"

# Find Linux HZ
declare -i NCTL_HZ=100

# Usage: reconf_find_linux_hz
reconf_find_linux_hz()
{
	local -ir DEFAULT_CONFIG_HZ=100
	local CONFIG_HZ
	local running_config pipe

	running_config="$NCTL_PROC_DIR/config.gz"
	if [ -f "$running_config" ]; then
		pipe='zcat'
	else
		running_config="/boot/config-$(uname -r)"
		if [ -f "$running_config" ]; then
			pipe='cat'
		else
			running_config='/boot/config'
			if [ -f "$running_config" ]; then
				pipe='cat'
			else
				pipe=''
			fi
		fi
	fi

	if [ -z "$pipe" ]; then
		NCTL_HZ=$DEFAULT_CONFIG_HZ
		return
	fi

	CONFIG_HZ="$(
		{
			"$pipe" "$running_config"|\
			sed -nEe's/^CONFIG_HZ=([[:digit:]]+)[[:space:]]*$/\1/p'
		} 2>/dev/null
	)"
	[ "$CONFIG_HZ" -gt 0 ] 2>/dev/null || CONFIG_HZ=$DEFAULT_CONFIG_HZ

	NCTL_HZ="$CONFIG_HZ"
	declare -r NCTL_HZ
}

reconf_find_linux_hz

# Keep namespace clean.
unset reconf_find_linux_hz

:

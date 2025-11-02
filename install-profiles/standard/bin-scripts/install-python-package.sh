#
# Description: Used by the roperdot install to install Python packages
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
install-python-package: install Python packages
Usage: install-python-package <package> [package ...]

install-python-package will install the named package(s) using Python 3 or
Python 2 depending on what's installed.

pip3 or pip will be used to install the package(s).
EOT
	exit 0
fi

# DEBUGGING=true
. "${ROPERDOT_DIR}/source-scripts/debug"
debug "install-python-package start"

debug "Installing python package(s) $@"

. "${ROPERDOT_DIR}/source-scripts/find-pip"
debug "pip_bin: $pip_bin"
if [[ -n "$pip_bin" ]]; then
	debug "Installing with $pip_bin"
    if $pip_bin install --help 2>&1 | grep -q "break-system-packages"; then
        debug "System supports --break-system-packages, assuming externally-managed"
        $pip_bin install --user --break-system-packages "$@"
    else
        $pip_bin install --user "$@"
    fi
else
	echo "Could not find a suitable installer; aborting installation of $@"
	exit 1
fi

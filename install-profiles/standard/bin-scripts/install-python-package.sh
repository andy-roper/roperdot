#
# Description: Used by the roperdot install to install a Python package
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
install-python-package: install a Python package
Usage: install-python-package <package-name>

install-python-package will install the named package using Python 3 or
Python 2 depending on what's installed.

pip3 or pip will be used to install the package.
EOT
	exit 0
fi

# DEBUGGING=true
. "${ROPERDOT_DIR}/source-scripts/debug"
debug "install-python-package start"

package=$1

debug "Installing python package $package"

. "${ROPERDOT_DIR}/source-scripts/find-pip"
debug "pip_bin: $pip_bin"
if [[ -n "$pip_bin" ]]; then
	debug "Installing with $pip_bin"
    if $pip_bin install --help 2>&1 | grep -q "break-system-packages"; then
        debug "System supports --break-system-packages, assuming externally-managed"
        $pip_bin install --user --break-system-packages "$package"
    else
        $pip_bin install --user "$package"
    fi
else
	echo "Could not find a suitable installer; aborting installation of $package"
	exit 1
fi

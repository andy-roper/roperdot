#
# Description: Updates ~/.config/roperdot/roperdot-os-functions and app binaries for the current OS
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
update-app-binaries: update roperdot-os-functions and app binaries for the current OS
Usage: update-app-binaries

This script will generate ~/.config/roperdot/roperdot-os-functions and build
scripts in ~/.config/roperdot/app-bin-bash and/or ~/.config/roperdot/app-bin-zsh
based on the machine's OS and the applications that are installed.

NOTE: The PROCESSING_BASH and PROCESSING_ZSH environment variables determine
which shells to generate scripts for. If neither is defined, the current shell
will be assumed.
EOT
    exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/update-app-binaries"
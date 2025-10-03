#
# Description: (Windows) Clears frequent places and recent items
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-?" ]]; then
	cat <<EOT
clear-recent: Clears frequent places and recent items
Usage: clear-recent
EOT
	exit 0
fi

source "$ROPERDOT_DIR/source-scripts/win-env-functions"

def_win_env_linux_path APPDATA
rm -rf "$APPDATA/Microsoft/Windows/Recent" 2>/dev/null
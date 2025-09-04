#
# Description: (Windows) Clears frequent places and recent items
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
source "$ROPERDOT_DIR/source-scripts/win-env-functions"

def_win_env_linux_path APPDATA
rm -rf "$APPDATA/Microsoft/Windows/Recent" 2>/dev/null
#
# Description: (Windows) Imports schemes into Windows Terminal settings and sets the current scheme
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
configure-windows-terminal
Usage: configure-windows-terminal

This script imports the schemes in roperdot/config/color-schemes/windows_terminal into
the Windows Terminal settings.json, and sets the scheme based on the value of
ROPERDOT_COMMON_COLOR_SCHEME.
EOT
    exit 0
fi

# Get Windows LOCALAPPDATA path
localappdata_windows=$(cmd.exe /c echo %LOCALAPPDATA% 2>/dev/null | tr -d '\r')
if [[ -z "$localappdata_windows" ]]; then
    echo "Error: could not get LOCALAPPDATA"
    exit 1
fi

localappdata_wsl=$(wslpath "$localappdata_windows")

# Try the most common location first
terminal_settings_file="${localappdata_wsl}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

# If not found, try the other location
if [[ ! -f "$terminal_settings_file" ]]; then
    terminal_settings_file="${localappdata_wsl}/Microsoft/Windows Terminal/settings.json"
fi

if [[ ! -f "$terminal_settings_file" ]]; then
    echo "Windows Terminal settings file was not found. Windows Terminal needs to be run at least once before this script is executed so settings.json will be present to update."
    exit 1
fi
. "${ROPERDOT_DIR}/source-scripts/windows-terminal-functions"
import_windows_terminal_color_schemes "$terminal_settings_file"
if [[ "$ROPERDOT_COMMON_COLOR_SCHEME" == default ]]; then
	target_scheme="Roperdot ${ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME}"
else
	target_scheme="Roperdot ${ROPERDOT_COMMON_COLOR_SCHEME}"
fi
# Update both defaults AND the Ubuntu profile
if /usr/bin/jq --arg scheme "$target_scheme" '
    .profiles.defaults.colorScheme = $scheme |
    .profiles.list[] |= if .name == "Ubuntu" then 
        .colorScheme = $scheme | 
        .font = {"face": "Hack Nerd Font"} 
    else . end
' "$terminal_settings_file" > tmp_terminal.json; then
    \mv tmp_terminal.json "$terminal_settings_file"
else
    echo "Failed to update Windows Terminal scheme"
    exit 1
fi
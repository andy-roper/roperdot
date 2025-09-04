#
# Description: (Windows) Bounces the wi-fi connection
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
bounce-wifi: bounce the wi-fi connection
Usage: bounce-wifi [wi_fi_connection]

The script will bounce the wi-fi connection. It will operate on the
"Wireless Network Connection" connection unless the name of a network
connection is provided as a parameter.
EOT
	exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/win-env-functions"

conn_name="Wireless Network Connection"

run_temp_batch () {
	cygstart --action=runas cmd /c "$temp_bat_win" >& nul
}

[[ $# -gt 0 ]] && conn_name="$1"

temp_bat="$(mktemp).bat"
temp_bat_win="$(wslwinpath "$temp_bat")"
cat << EOT >> "$temp_bat"
Disabling $conn_name
netsh interface set interface name=\"$conn_name\" admin=disabled
EOT
run_temp_batch
echo Waiting 3 seconds
sleep 3
echo Enabling $conn_name
echo netsh interface set interface name=\"$conn_name\" admin=enabled > $temp_bat
run_temp_batch
\rm $temp_bat >/dev/null
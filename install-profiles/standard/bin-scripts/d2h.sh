#
# Description: Converts decimal number to hexadecimal
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
d2h: convert a decimal number to hexadecimal
Usage: d2h <number> [...]

This script will convert decimal numbers to hexadecimal. If the generated
number has an odd number of digits, a zero will be prepended. If multiple
numbers are provided, they'll each be converted and the results concatenated,
such as for 3 decimal RGB values.
EOT
	exit 0
fi

dec2hex() {
	local h=$(printf "%x" "$1")
	local len=${#h}
	[[ $((len % 2)) -ne 0 ]] && h="0$h"
	echo "$h"
}

for v; do
	h=$(dec2hex "$v")
	hex_val="${hex_val}${h}"
done
echo "0x${hex_val}"

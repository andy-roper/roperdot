#
# Description: Converts hexadecimal number to decimal
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
h2d: convert a hexadecimal number to decimal
Usage: h2d <number>

This script will convert a hexadecimal number to decimal.
EOT
	#'
	exit 0
fi

h=${1#0x}
echo $(( 16#$h ))
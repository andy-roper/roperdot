#
# Description: Echoes a random value between a lower and upper bound
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# == 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] ; then
	cat <<EOT
random: print a random number
Usage: random [min] <max>

Prints a random integer between and including the min and max values. If only
max is supplied, min will default to 1.
EOT
	exit 0
fi
if [[ $# == 1 ]]; then
	min=1
	max=$1
else
	min=$1
	max=$2
fi
[[ $max == % ]] && max=100
echo $((RANDOM % (max - min + 1) + min))
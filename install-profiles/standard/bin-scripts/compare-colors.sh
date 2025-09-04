#
# Description: Prints several colors for comparison, e.g. compare-colors black 16 233 234 235
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -lt 2 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
compare-colors: compare 256-color terminal colors to a named color
Usage: compare-colors <color-name> <color> [...]

The color name should be one of: black, red, green, yellow, blue, magenta,
cyan, white, brblack, brred, brgreen, bryellow, brblue, brmagenta, brcyan,
or brwhite.

Example:
compare-colors red 100 150 200 250
EOT
	exit 0
fi

color=$1
shift

declare -A ansi_color
ansi_color=(
 	["black"]="0"
	["red"]="1"
	["green"]="2"
	["yellow"]="3"
	["blue"]="4"
	["magenta"]="5"
	["cyan"]="6"
	["white"]="7"
 	["brblack"]="8"
	["brred"]="9"
	["brgreen"]="10"
	["bryellow"]="11"
	["brblue"]="12"
	["brmagenta"]="13"
	["brcyan"]="14"
	["brwhite"]="15"
)

terminal_index="${ansi_color[$color]}"
terminal_color_sequence="$(tput setaf $terminal_index)"

while (( $# )); do
	test_color_sequence="$(tput setaf $1)"
	printf "%s%s %scolor %d\n" $terminal_color_sequence $color $test_color_sequence $1
	shift
done

echo -e "\e[0m"
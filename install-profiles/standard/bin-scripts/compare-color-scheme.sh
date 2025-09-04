#
# Description: Prints colors defined in a color scheme's color-defs.txt file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
. "${ROPERDOT_DIR}/source-scripts/re-match"

if [[ $# -eq 0 ]]; then
	cat <<EOT
compare-color-scheme: compare tput setaf colors to terminal colors
Usage: compare-color-scheme <color defs file>

This script will read a color-defs.txt file (such as
roperdot/config/color-schemes/source/hybrid/color-defs.txt) and for each of
the 16 ANSI colors show the tput setaf color side-by-side with the color
being used for that ANSI color in the terminal settings.
EOT
	exit 0
fi

f=$1
declare -A ansi_color
ansi_color=(
 	["BLACK"]="0"
	["RED"]="1"
	["GREEN"]="2"
	["YELLOW"]="3"
	["BLUE"]="4"
	["MAGENTA"]="5"
	["CYAN"]="6"
	["WHITE"]="7"
 	["BRBLACK"]="8"
	["BRRED"]="9"
	["BRGREEN"]="10"
	["BRYELLOW"]="11"
	["BRBLUE"]="12"
	["BRMAGENTA"]="13"
	["BRCYAN"]="14"
	["BRWHITE"]="15"
)

# Had to change the regex pattern for zsh compatibility
# re="^(.*)[[:space:]]+([0-9]+)$"
re="^([A-Z]+)[^0-9]+([0-9]+)$"
while IFS= read line; do
	if re_match "$line" $re; then
		color=${re_match[1]}
		index=${re_match[2]}
		color_sequence="$(tput setaf $index)"
		terminal_index="${ansi_color[$color]}"
		terminal_color_sequence="$(tput setaf $terminal_index)"
		printf "%s%-12s%3s  %sterminal %-12s\n" $color_sequence $color $index $terminal_color_sequence $color
	fi
done < "$f"

echo -e "\e[0m"
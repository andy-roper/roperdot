#
# Description: Prints the number of colors XTerm supports
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
#
# Original script by Victor Engmark
# Source: https://github.com/l0b0/xterm-color-count
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# Full license text is in x-term-color-count.license.txt

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
xterm-color-count: print the number of colors XTerm supports
Usage: xterm-color-count [number of colors to show]

This script originates from this GitHub project:
https://github.com/l0b0/xterm-color-count
EOT
	#'
	exit 0
fi

max=$(tput colors)

setfg () {
	printf '\e[38;5;%dm' $1
}
setbg () {
	printf '\e[48;5;%dm' $1
}
showcolors () {
	# Given an integer, display that many colors 
	for ((i = 0; i < $1; i++)); do
		printf '%4d ' "$i"
		setbg "$i"
		tput el
		tput sgr0
		echo
	done
	tput sgr0 el
}

# Clean up even if user hits ^C
trap 'tput sgr0; exit' INT

# If -v is given, show all the colors
case ${1-none} in
	none)
		echo $max
	;;
	-v)
		showcolors $max
	;;
	*)
		if [[ "$1" -gt 0 ]]; then
			showcolors "$1"
		else
		    echo $max
		fi
	;;
esac | less --raw-control-chars --QUIT-AT-EOF --no-init
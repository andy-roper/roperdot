#
# Description: Displays a map of terminal colors
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
        cat <<EOT
show-colormap: display a terminal color map
EOT
        exit 0
fi

if [[ $ROPERDOT_CURRENT_SHELL = zsh ]]; then
	for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
else
	for i in {0..255}; do
		printf "\033[48;5;${i}m  \033[0m\033[38;5;${i}m%03d\033[0m " "$i"
		if (( i % 6 == 3 )); then
			echo;
		fi
	done
fi
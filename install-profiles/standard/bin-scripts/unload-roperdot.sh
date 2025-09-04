#
# Description: Resets ~/.dircolors and ~/.vimrc to their contents before roperdot was started
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
unload-roperdot: unload roperdot ls colors and vim settings

unload-roperdot resets ~/.dircolors and ~/.vimrc to their contents before
roperdot was started.
EOT
	exit 0
fi

if [[ -e ~/.dircolors.bak ]] && grep -v "ROPERDOT" ~/.dircolors.bak >/dev/null; then
	\mv ~/.dircolors.bak ~/.dircolors
else
	grep -v "ROPERDOT" ~/.dircolors >/dev/null && \rm ~/.dircolors
fi
#if [[ -e ~/.lessfilter.bak ]] && grep -v "ROPERDOT" ~/.lessfilter.bak >/dev/null; then
#	\mv ~/.lessfilter.bak ~/.lessfilter
#else
#	grep -v "ROPERDOT" ~/.lessfilter >/dev/null && \rm ~/.lessfilter
#fi
#if [[ -e ~/.vimrc.bak ]] && grep -v "ROPERDOT" ~/.vimrc.bak >/dev/null; then
#	\mv ~/.vimrc.bak ~/.virmc
#else
#	grep -v "ROPERDOT" ~/.vimrc >/dev/null && \rm ~/.vimrc
#fi
[[ -e ~/.vimrc.bak ]] && \mv ~/.vimrc.bak ~/.vimrc
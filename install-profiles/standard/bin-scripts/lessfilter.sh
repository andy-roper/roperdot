#
# Description: Used to call pygmentize on files displayed with less
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
lessfilter: used to call pygmentize on files displayed with less
Usage: lessfilter <filespec>
EOT
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

[[ $current_shell = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

case "${1##*/}" in
	*.@(awk|groff|java|js|m4|php|pl|pm|pod|sh|ad[asb]|asm|inc|\
	c|h|[ch]pp|[ch]xx|cc|hh|lsp|l|pas|p|xml|xps|xsl|axp|ppd|pov|\
	diff|patch|py|rb|sql|ebuild|eclass|htm|html|ts|json))
		pygmentize -O style=roperdot -f 256 "$1" 2>/dev/null
		;;
	.bashrc|.bash_profile|.bash_aliases|.bash_environment|.zshrc|.p10k.zsh|.fzf.bash|.fzf.zsh)
		pygmentize -O style=roperdot -f 256 -l sh "$1" 2>/dev/null
		;;
	*)
		first_line=$(head -1 "$1")
		if echo "$first_line" | grep "perl" >/dev/null; then
			pygmentize -O style=roperdot -f 256 -l perl "$1" 2>/dev/null
		elif echo "$first_line" | grep "python" >/dev/null; then
			pygmentize -O style=roperdot -f 256 -l python "$1" 2>/dev/null
		else
			# Assume a file with no extension without a perl or python shebang is a shell script
			pygmentize -O style=roperdot -f 256 -l sh "$1" 2>/dev/null
		fi
esac

exit 0
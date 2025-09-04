#
# Description: Finds matching files in a path
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
show_help () {
	cat <<EOT
lf: find matching files in a path
Usage: lf [-adr] [path and pattern]

Options:
-a  list files and directories
-d  list only directories
-r  recurse subdirectories

Prints a list of files in the path using the pattern in the argument. If no
path is provided in the argument, the current directory will be used. By
default only files will be listed. The -a and -d switches can be used to
list files and directories or just directories respectively.

Examples:
lf *.pl
lf ~/bin/*.pl
EOT
	exit 0
}

[[ "$1" = "--help" ]] && show_help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

. "${ROPERDOT_DIR}/source-scripts/re-match"

OPTIND=1
switches="-maxdepth 1"
file_type=f

while getopts "h?adr" opt; do
	case "$opt" in
		a) unset file_type ;;
		d) file_type=d ;;
		r) unset switches ;;
		*) show_help ;;
	esac
done

shift $(( OPTIND - 1 ))

[[ -n "$file_type" ]] && switches="$switches -type $file_type"

if [[ $# -eq 0 ]]; then
	searchpath="$(pwd)"
else
	re="^(.*)/([^/]*)$"
#	if [[ "$1" =~ $re ]]; then
#		searchpath="${BASH_REMATCH[1]}"
#		pattern="${BASH_REMATCH[2]}"
	if re_match "$1" $re; then
		searchpath="${re_match[1]}"
		pattern="${re_match[2]}"
	elif [[ -d "$1" ]]; then
		searchpath="$1"
	else
		searchpath="$(pwd)"
		pattern="$1"
	fi
fi
[[ $current_shell = zsh ]] && setopt sh_word_split
if [[ -n "$pattern" ]]; then
	find "$searchpath" $switches -iname "$pattern" 2>/dev/null
else
	find "$searchpath" $switches 2>/dev/null
fi
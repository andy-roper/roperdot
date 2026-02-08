#
# Description: Used by v to display the contents of a file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
show-file: display the contents of a file
Usage: show-file [-b] <file>

Options:
-b  Display as binary data using xxd or hexdump

show-file will show the contents of a file. If the -b switch is used or if the
file isn't of a set of known text file extensions, it will be displayed as
binary data using xxd or hexdump.

If number of lines in the data to be displayed will fit in the window, cat
will be used to print the file's contents. Otherwise, less will be used to
view the data.
EOT
	exit 0
fi

[[ $ROPERDOT_CURRENT_SHELL = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

if [[ "$1" = "-b" ]]; then
	show_binary=1
	shift
fi

lines_in_file () {
	echo $( wc -l "$1" | awk '{print $1;}' )
}

if command -v tput >/dev/null 2>&1; then
	lines_available=$(tput lines)
else
	lines_available=$(stty -a | tr \; \\012 | grep rows | tr -d ' rows')
fi
(( --lines_available ))

#if [[ -z "$show_binary" ]]; then
#	filebase="$(basename "$1")"
#	re1="^\."
#	re2="\."
#	re3="\.(txt|pl|sh|html?|css|js|json|ts|spec|xml|xslt|md|yml|dot|java|c|cpp|h|bak|ini|cs|cfg|inf|properties|out|err)$"
#	re4="/tmp.[^./]+$"
#	if [[ "$filebase" =~ $re1 ]] || ! [[ "$filebase" =~ $re2 ]] || [[ "$filebase" =~ $re3 ]] || [[ "$filebase" =~ $re4 ]]; then
#		:
#	else
#		show_binary=1
#	fi
#fi
if [[ -z "$show_binary" ]]; then
	f=$1
else
	temp_file=$(mktemp)
	f=$temp_file
	if command -v xxd >/dev/null 2>&1; then
		xxd "$1" > "$temp_file"
	else
		hexdump -C "$1" > "$temp_file"
	fi
fi
lines_in_file=$(lines_in_file "$f")

handle_error() {
	if [[ "$(cat $1)" = "Error: Could not find style module 'roperdot'." ]]; then
		cat <<EOT
Error: Pygments style module roperdot not found
If you've recently upgraded Python, you'll need to install the roperdot style for the new Python version.
On a Mac, you may need to edit the pygmentize script to have the shebang reference the Python version in use.
EOT
	elif ! grep -q BrokenPipeError "$1"; then
		cat $1
	fi
	rm $1
}

# print the file to the terminal if it will fit in the window or if we're piping/redirecting output (! -t 1)
if [[ "$lines_in_file" -lt "$lines_available" || ! -t 1 ]]; then
	if command -v pygmentize >/dev/null 2>&1; then
		error_file=$(mktemp)
		[[ $ROPERDOT_CURRENT_SHELL = bash ]] && shopt -s extglob nocasematch || setopt ksh_glob nocasematch

		case "${f##*/}" in
		    *.@(awk|groff|java|js|m4|php|pl|pm|pod|sh|ad[asb]|asm|inc|\
		    c|h|[ch]pp|[ch]xx|cc|hh|lsp|l|pas|p|xml|xps|xsl|axp|ppd|pov|\
		    diff|patch|py|rb|sql|ebuild|eclass|htm|html|ts|json))
		    	pygmentize -O style=roperdot -f 256 "$f" 2>"$error_file"
		    	;;
		    .bashrc|.bash_profile|.bash_aliases|.bash_environment|.zshrc|.p10k.zsh|.fzf.bash|.fzf.zsh|fzf.bash|fzf.zsh)
		        pygmentize -O style=roperdot -f 256 -l sh "$f" 2>"$error_file"
		        ;;
		    *)
				first_line=$(head -1 "$1")
				if echo "$first_line" | grep "perl" >/dev/null; then
					pygmentize -O style=roperdot -f 256 -l perl "$f" 2>"$error_file"
		        elif echo "$first_line" | grep "python" >/dev/null; then
		            pygmentize -O style=roperdot -f 256 -l python "$f" 2>"$error_file"
		        else
					# Assume a file with no extension without a perl or python shebang is a shell script
		            pygmentize -O style=roperdot -f 256 -l sh "$f" 2>"$error_file"
		        fi
		esac
		handle_error "$error_file"
	else
		cat "$f"
	fi
	echo
else
	error_file=$(mktemp)
	less "$f" 2>"$error_file"
	handle_error "$error_file"
fi
[[ -n "$temp_file" ]] && rm "$temp_file"
#
# Description: Changes to a parent directory
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
_up: cd up to a parent directory
Usage: up [prefix | count]

The _up script is called by the up function.

If a numeric count is provided, cd up that number of directories.

If a prefix string is provided, cd up to the first parent directory that begins
with the prefix.

If no arguments are provided, prompt the user to select the target directory
from a list. fzf will be used for the selection if it's installed.
EOT
	exit 0
fi
if [[ $# -eq 0 ]]; then
	if [[ $ROPERDOT_CURRENT_SHELL = zsh ]]; then
		pwd="$(pwd)"
		parts=("${(@s|/|)pwd}")
		parts[1]="/"
		parts[${#parts[@]}]=()
		count=2
	else
		IFS='/' read -ra parts <<< "$(pwd)"
		unset 'parts[${#parts[@]} - 1]'
		parts[0]="/"
		count=1
	fi
	if [[ ${#parts[@]} -eq 1 ]]; then
		dest=..
	else
		if command -v fzf >/dev/null 2>&1; then
			height=$(( ${#parts[@]} + 2 ))
			(( height > LINES / 2 )) && height=50%
			index=$(printf "%s\n" "${parts[@]}" | cat -n | fzf -0 --tac --no-sort --height $height --layout=reverse --with-nth 2.. | awk '{print $1}')
		else
			PS3="Destination directory? "
			COLUMNS=1
			for value in "${parts[@]}"; do
				[[ ${#value} -gt $COLUMNS ]] && COLUMNS=${#value}
			done
			select dest_dir in "${parts[@]}"; do
				break
			done
			index=$REPLY
		fi
		if [[ -n $index ]]; then
			if [[ $index -eq 1 ]]; then
				dest=/
			else
				dest=
				[[ $ROPERDOT_CURRENT_SHELL = bash ]] && (( --index ))
				while [[ $count -le $index ]]; do
					dest="$dest/${parts[$count]}"
					(( ++count ))
				done
			fi
		fi
	fi
	echo "$dest"
elif [[ "$1" =~ ^[0-9]+$ ]]; then
	count=$1
	while (( count-- )); do
		CDSTR="../$CDSTR"
	done
	echo "$CDSTR"
else
#	if [[ $ROPERDOT_OS_ENV = darwin ]]; then
#		dest="$(perl -nle'print $1 if m{^(.*/'"$1"'.*?)(?=(?:/.*)?/[^/]+$)}' <<< "$(pwd)")"
#	else
#		dest="$(grep -oP "^(.*/$1.*?)(?=(?:/.*)?/[^/]+\$)" <<< "$(pwd)")"
#	fi
	if [[ $ROPERDOT_CURRENT_SHELL = zsh ]]; then
		unsetopt case_match
		pwd="$(pwd)"
		parts=("${(@s|/|)pwd}")
		parts[${#parts[@]}]=()
		while [[ ${#parts[@]} -gt 0 ]]; do
			if [[ $parts[${#parts[@]}] =~ ^$1 ]]; then
				dest="${(j:/:)parts}"
				break
			fi
			parts[${#parts[@]}]=()
		done
	else
		IFS='/' read -ra parts <<< $(pwd)
		unset 'parts[${#parts[@]} - 1]'
		while [[ ${#parts[@]} -gt 0 ]]; do
			if [[ "${parts[${#parts[@]} - 1]}" =~ ^$1 ]]; then
				dest="$(IFS='/'; echo "${parts[*]}")"
				break
			fi
			unset 'parts[${#parts[@]} - 1]'
		done
	fi
	[[ -n "$dest" ]] && echo "$dest" || return 1
fi
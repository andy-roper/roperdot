#
# Description: Used by scripts to find the alphanumerically maximum file for a pattern, e.g. for the latest version matching a string prefix
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
max-file-for-pattern: find the alphanumerically maximum file for a pattern
Usage: max-file-for-pattern [-d|-f] <directory> <pattern> [...]

max-file-for-pattern will search for the alphanumerically maximum file or
directory that matches a pattern within a directory. This is usually used to
find the latest version of an application matching a string prefix.

-d  Search should only match directories
-f  Search should only match files

Example call:
max-file-for-pattern "/cygdrive/c/Program Files/Java" -d "jdk(.*)" "jre(.*)"
EOT
	exit 0
}

[[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

. "${ROPERDOT_DIR}/source-scripts/re-match"

declare file_type largest_file largest_version
if [[ "$1" = "-d" ]]; then
	file_type=d
	shift
elif [[ "$1" = "-f" ]]; then
	file_type=f
	shift
fi
d="$1"
[[ -z "$d" ]] && help
shift
patterns=()
for pattern; do
	patterns+=("^${pattern}$")
done
[[ "${#patterns[@]}" -eq 0 ]] && help

process_max_ffp_file () {
	local filename="$f"
	f="${f##*/}"
	if [[ $current_shell = zsh ]]; then
		local initial_value=1
		local max_value=$(( $#patterns + 1 ))
	else
		local initial_value=0
		local max_value=${#patterns[@]}
	fi
	for ((i = initial_value; i < max_value; i++)); do
		local pattern="${patterns[$i]}"
		if re_match "$f" "$pattern"; then
			if [[ -z "$largest_version" || "${re_match[1]}" > "$largest_version" ]]; then
				largest_file="$filename"
				largest_version="${re_match[1]}"
				break;
			fi
		fi
	done
}

if [[ -n "$file_type" ]]; then
	while IFS= read f; do
		process_max_ffp_file
	done < <(find "$d" -mindepth 1 -maxdepth 1 -type $file_type)
else
	while IFS= read f; do
		process_max_ffp_file
	done < <(find "$d" -mindepth 1 -maxdepth 1)
fi
echo "$largest_file"
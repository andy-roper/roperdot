#
# Description: Replaces text in files
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
rt: replace text in files
Usage: rt [-acfhr] <search_pattern> <replace_str> [filespec ...]

rt performs case-insensitive matches for file names and matches for the search
pattern by default. By default replacements will be prompted for interactively.
This can be overridden with the -f switch.

By default hidden files that are not CVS-related will be searched.

Perl compatible regular expressions are used by this script's supporting
applications (The Silver Searcher, Vim and Perl [naturally]).

Non-greedy matching should not be used in search patterns for interactive
replacements because Vim doesn't support it.

Switches
-c  Do case-sensitive file name and search pattern searches
-e  Exclude hidden files from being searched
-f  Force replacement of strings without prompting the user for each replacement,
    but prompt the user per file affected
-F  Force replacement with no approvals from the user
-h  Show help
-r  Recurse subdirectories
EOT
	exit 0
}

[[ $# -eq 0 ]] && help

. "${ROPERDOT_DIR}/source-scripts/re-match"
. "${ROPERDOT_DIR}/source-scripts/input-functions"

case_sensitive=false
recurse_flag=--no-recurse
type_flag=--hidden
while [[ "$1" =~ ^- ]]; do
	[[ "$1" = -- ]] && shift && break
	[[ "$1" = help || "$1" = "-?" || "$1" =~ [hH] ]] && help
	[[ "$1" =~ [cC] ]] && case_sensitive=true
	[[ "$1" =~ [eE] ]] && unset type_flag
	[[ "$1" =~ [f] ]] && automatic=true
	[[ "$1" =~ [F] ]] && approveAll=true
	[[ "$1" =~ [rR] ]] && unset recurse_flag
	shift
done

[[ $# -lt 2 ]] && help

[[ "$ROPERDOT_CURRENT_SHELL" = bash ]] && set +f || set +F
pattern="$1"
replace_str="$2"
shift 2

pattern="${pattern//\//\\/}"
replace_str="${replace_str//\//\\/}"
[[ "$case_sensitive" = true ]] && case_flag=--case-sensitive || case_flag=--ignore-case
OLD_IFS=$IFS
if [[ $# -eq 0 ]]; then
	IFS=$'\n' file_array=($(ag $case_flag $type_flag $recurse_flag --files-with-matches "$pattern" "."))
else
	declare -a file_array
	while [[ $# -gt 0 ]]; do
		if [[ -d "$1" ]]; then
			target_dir="$1"
			file_pattern=".*"
		else
			if re_match "$1" "^(.*)/(.*?)$"; then
				file_pattern="${re_match[2]}"
				target_dir="${re_match[1]}"
			else
				file_pattern="$1"
				target_dir="."
			fi
			file_pattern="${file_pattern/\./\\.}"
			file_pattern="${file_pattern/\*/.*}"
		fi
		IFS=$'\n' list=($(ag $case_flag $type_flag $recurse_flag --file-search-regex "$file_pattern\$" --files-with-matches "$pattern" "$target_dir"))
		file_array=("${file_array[@]}" "${list[@]}")
		shift
	done
fi
IFS=$'\n' file_array=($(sort -f <<<"${file_array[*]}"))
IFS=$OLD_IFS
if [[ ${#file_array} -eq 0 ]]; then
	echo "No files found matching the pattern"
	exit 0
fi
if [[ -n "$approveAll" ]]; then
	echo "Replacing text in the listed files:"
	printf '%s\n' "${file_array[@]}"
	[[ "$case_sensitive" = true ]] && regex="s/${pattern}/${replace_str}/g" || regex="s/${pattern}/${replace_str}/gi"
	printf '%s\0' "${file_array[@]}" | xargs -0 perl -p -i -e "$regex"
elif [[ -n "$automatic" ]]; then
	printf '%s\n' "${file_array[@]}"
	if [[ "$case_sensitive" = true ]]; then
		echo "Case-sensitive matches of $pattern in ${#file_array} files."
	else
		echo "Case-insensitive matches of $pattern in ${#file_array} files."
	fi
	ask_yn_n "Replace text in the listed files" || exit 0
	[[ "$case_sensitive" = true ]] && regex="s/${pattern}/${replace_str}/g" || regex="s/${pattern}/${replace_str}/gi"
	printf '%s\0' "${file_array[@]}" | xargs -0 perl -p -i -e "$regex"
else
	for f in "${file_array[@]}"; do
		echo "$f:"
		ag $case_flag "$pattern" "$f"
		while : ; do
			read_input "[I]nteractively process replacements, [s]kip file or [a]ccept all replacements [I/s/a]?"
			[[ -z "$REPLY" || "$REPLY" =~ ^[Ii]$ ]] && answer=i && break
			[[ "$REPLY" =~ ^[Ss]$ ]] && answer=s && break
			[[ "$REPLY" =~ ^[Aa]$ ]] && answer=a && break
		done
		if [[ "$answer" != s ]]; then
			if [[ "$answer" = i ]]; then
				[[ "$case_sensitive" = true ]] && regex="%s/${pattern}/${replace_str}/gc" || regex="%s/${pattern}/${replace_str}/gci"
				vim -c "$regex" -c 'wq' "$f"
			else
				[[ "$case_sensitive" = true ]] && regex="s/${pattern}/${replace_str}/g" || regex="s/${pattern}/${replace_str}/gi"
				perl -p -i -e "$regex" "$f"
				echo "Matches replaced in $f"
			fi
		fi
		echo 
	done
fi
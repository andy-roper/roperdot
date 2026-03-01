#
# Description: Allows the user to select a file from a piped list for editing.
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ -t 0 ]]; then
	cat <<EOT
find-edit: allow the user to select a file from a piped list for editing
Usage: find-edit

find-edit will take in a piped list of search output from Silver Searcher or
grep and allow the user to select one using fzf. When a file is selected, the
file will be opened with vi on the specified line (if available).
EOT
	exit 0
fi

selection=$(fzf --ansi --height=50% --layout=reverse < /dev/stdin)
[[ -n "$selection" ]] || exit 0
file_name="$(echo "$selection" | cut -d: -f1)"
line_number="$(echo "$selection" | cut -d: -f2)"

if [[ "$line_number" =~ ^[0-9]+$ ]]; then
    vi "+${line_number}" "${file_name}" < /dev/tty
else
    vi "${file_name}" < /dev/tty
fi
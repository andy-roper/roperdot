#
# Description: Inserts a block of text into a file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# TODO
# Add support for nth match, i.e. to insert the new text before the nth match
# of before-line-text in target-file

help () {
	cat <<EOT
insert-text: insert a block of text into a file
Usage: insert-text [OPTIONS] <target-file> <text-file> <pattern>

The text in text-file will be inserted in the target-file before the first line
containing the pattern.

Before modifying a file, a backup will be created in the same directory as the
file (unless a backup is already present).

Options
--after            Insert text after pattern instead of before pattern
--new-backup       Overwrite the existing backup.
--no-blank-after   Don't add a blank line after the inserted text.
--no-blank-before  Don't add a blank line before the inserted text.
--no-blank-lines   Don't add a blank line before or after the inserted text.
EOT
	exit 0
}

if [[ $# -lt 3 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	help
fi

while :; do
	if [[ "$1" == "--after" ]]; then
		insert_after=true
		shift
	elif [[ "$1" == "--new-backup" ]]; then
		new_backup=true
		shift
	elif [[ "$1" == "--no-blank-after" ]]; then
		no_blank_after=true
		shift
	elif [[ "$1" == "--no-blank-before" ]]; then
		no_blank_before=true
		shift
	elif [[ "$1" == "--no-blank-lines" ]]; then
		no_blank_after=true
		no_blank_before=true
		shift
	else
		break
	fi
done
[[ $# -ne 3 ]] && help
target="$1"
text_file="$2"
pattern="$3"
if [[ ! -f "$target" ]]; then
	echo "Target file not found"
	exit 1
fi
if [[ ! -f "$text_file" ]]; then
	echo "Text file not found"
	exit 1
fi

if [[ -n $new_backup || ! -f "$target.insert-text.backup" ]]; then
	src="$target.insert-text.backup"
else
	temp_backup=true
	src=$(mktemp)
fi
cp "$target" "$src"

# Get line number of text in target file
line=$(grep -n "$pattern" "$src")
if [[ -z "$line" ]]; then
	echo "Pattern not found in file"
	[[ -n $temp_backup ]] && rm "$src" >/dev/null 2>&1
	exit 0
fi
line=${line%%:*}

if [[ -n $insert_after ]]; then
	head -$((line)) "$src" > "$target"
else
	head -$((line - 1)) "$src" > "$target"
fi

[[ -n $no_blank_before ]] || echo >> "$target"

cat "$text_file" >> "$target"

[[ -n $no_blank_after ]] || echo >> "$target"

# Append from src at line to end to target file
if [[ -n $insert_after ]]; then
	tail -n +$((line + 1)) "$src" >> "$target"
else
	tail -n +$line "$src" >> "$target"
fi

[[ -n $temp_backup ]] && rm "$src" >/dev/null 2>&1
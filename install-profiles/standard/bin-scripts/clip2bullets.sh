#
# Description: Converts a bulleted presentation slide image in the clipboard to text
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
clip2bullets: convert a bulleted presentation slide image in the clipboard to text
Usage: clip2bullets
The image in the clipboard will be converted to text using tesseract and
then pasted into the clipboard.
EOT
#'
	exit 0
fi
if [[ -n "$1" ]]; then
	temp_img="$1"
else
	temp_img="$(mktemp --suffix=.png)"
fi
clip2png "$temp_img"
if [[ -f "$temp_img" && -s "$temp_img" ]]; then
	if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
		clip_app=clip.exe
	elif [[ "$ROPERDOT_DESKTOP_ENV" = "mac" ]]; then
		clip_app=pbcopy
	else
		clip_app="xclip -selection clipboard"
	fi
	png2text "$temp_img" | \
	    # replace leading character followed by space with dash
		sed 's/^. /- /' | \
		# combine consecutive lines for the same bullet point
		sed ':a; /^- /{N; /\n[^-]/{ s/\n/ /; ba}}' | \
		# replace mdash and ndash
		sed 's/—/\&mdash;/g; s/–/\&ndash;/g' | \
		# replace pipe with 1
		sed 's/|/1/g' | \
		# replace letter O following a digit with 0
		sed 's/\\d\([O]*\)/\\d\1/g; s/O/0/g' | \
		# replace I/0 with I/O
		sed 's/I\/0/I\/O/g' | \
		# fix MiB and GiB
		sed 's/mib/MiB/gI; s/gib/GiB/gI' | \
		# replace 0 followed by letters with O
		sed 's/0\([a-z]\)/O\1/gI' | \
		sed '/^$/d' | $clip_app
else
    echo "No image found in clipboard or failed to save"
fi
# Clean up
rm "$temp_img"
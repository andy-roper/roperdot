#
# Description: Converts a PNG to text
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
png2text: converts a PNG to text
Usage: png2text [image-path]

If no image path is passed, the script will look for an image in the clipboard
to process. The image will be converted to text using tesseract.
EOT
#'
	exit 0
fi

if [[ $# -eq 0 ]]; then
	using_temp_file=true
	png_path="$(mktemp --suffix=.png)"
	clip2png "$png_path"
	if [[ ! -f "$png_path" || ! -s "$png_path" ]]; then
		echo "No image found in clipboard or failed to save"
		exit 1
	fi
else
	png_path="$1"
fi

tesseract "$png_path" stdout 2>&1 | grep -v "Estimating resolution"

[[ -n "$using_temp_file" ]] && rm "$png_path" >/dev/null 2>&1
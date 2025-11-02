#
# Description: Saves an image in the clipboard as a PNG file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
clip2png: save an image in the clipboard as a PNG file
Usage: clip2png [--markdown] [--three-digits] <output_file>
       clip2png [--markdown] [--three-digits] --next <base_name>
       clip2png [--markdown] [--three-digits] --next --base-name-file <file> 

Options:
--base-name-file <file>  File which contains the base name to use
--markdown               Store markdown for the image in the clipboard
--next [base_name]       Create the next available numbered file (e.g., "Saved 03.png")
                         Supports 2-digit indexes (01-99)
                         base_name is required if --base-name-file is not used
--three-digits           Use three-digit numbering with next instead of two digits

If the clip2png_dir environment variable is defined, that will be used as the
destination directory for creating images unless the output file contains a path.
Otherwise, the current directory will be used.

If the markdown option is used and clip2png_markdown_dir is defined, that will
be used as the directory in the src attribute in the returned markdown.
Otherwise, the directory used will be ./images.
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

while [[ $# -ne 0 ]]; do
	if [[ "$1" =~ ^-- ]]; then
		if [[ "$1" == "--markdown" ]]; then
			storing_markdown=true
		elif [[ "$1" == "--next" ]]; then
			processing_next=true
		elif [[ "$1" == "--base-name-file" ]]; then
			using_base_name_file=true
		elif [[ "$1" == "--three-digits" ]]; then
			three_digit_numbering=true
		else
			help
		fi
	else
		if [[ -n "$using_base_name_file" ]]; then
			if [[ ! -f "$1" ]]; then
				echo "Error: file specified with --base-name-file not found"
				exit 1
			fi
			using_base_name_file=
			value="$(cat "$1")"
		else
			value="$1"
		fi
	fi
	shift
done

[[ -z "$value" || -d "$value" ]] && help

path_prefix=
if [[ ! "$value" =~ / && -n "$clip2png_dir" ]]; then
	if [[ ! -d "$clip2png_dir" ]]; then
		echo "Error: destination directory $clip2png_dir not found"
		exit 1
	fi
	path_prefix="$clip2png_dir"
	[[ "$path_prefix" =~ /$ ]] || path_prefix="${path_prefix}/"
fi

if [[ -n "$processing_next" ]]; then
	base_name="${path_prefix}$value"

	if [[ -n "$three_digit_numbering" ]]; then
		for i in {001..999}; do
			candidate="${base_name} ${i}.png"
			if [[ ! -f "$candidate" ]]; then
				png_path="$candidate"
				break
			fi
		done
		
		if [[ -z "$png_path" ]]; then
			echo "Error: All numbered files from ${base_name} 001.png to ${base_name} 999.png already exist" >&2
			exit 1
		fi
	else		
		for i in {01..99}; do
			candidate="${base_name} ${i}.png"
			if [[ ! -f "$candidate" ]]; then
				png_path="$candidate"
				break
			fi
		done
		
		if [[ -z "$png_path" ]]; then
			echo "Error: All numbered files from ${base_name} 01.png to ${base_name} 99.png already exist" >&2
			exit 1
		fi
	fi
else
	png_path="${path_prefix}$value"
fi

[[ "$png_path" == *".png" ]] || png_path="${png_path}.png"

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	powershell.exe -command "
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
\$img = Get-Clipboard -Format Image
if (\$img) {
    \$img.Save('$(wslpath -w "$png_path")', [System.Drawing.Imaging.ImageFormat]::Png)
    \$img.Dispose()
    Write-Host 'Saved to: $png_path'
} else {
    Write-Host 'No image found in clipboard' -ForegroundColor Red
    exit 1
}
"
elif [[ "$ROPERDOT_DESKTOP_ENV" = "mac" ]]; then
	if pngpaste "$png_path" 2>/dev/null; then
		echo "Saved to: $png_path"
	else
		echo "Error: No image found in clipboard or failed to save" >&2
		exit 1
	fi
else
	if xclip -selection clipboard -t image/png -o > "$png_path" 2>/dev/null; then
		echo "Saved to: $png_path"
	else
		echo "Error: No image found in clipboard or failed to save" >&2
		exit 1
	fi
fi

if [[ -n "$storing_markdown" ]]; then
	if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
		clip_app=clip.exe
	elif [[ "$ROPERDOT_DESKTOP_ENV" = "mac" ]]; then
		clip_app=pbcopy
	else
		clip_app="xclip -selection clipboard"
	fi
	filename=$(basename "$png_path")
	name="${filename%.*}"
	dir="$clip2png_markdown_dir"
	[[ -n "$dir" ]] || dir="./images"
	echo "<img src=\"${dir}/${filename}\" alt=\"${name}\" align=\"left\"/>" | $clip_app
fi
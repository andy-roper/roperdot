#
# Description: Saves an image in the clipboard as a PNG file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
clip2png: save an image in the clipboard as a PNG file
Usage: clip2png [--markdown] <output_file>
       clip2png [--markdown] --next <base_name>

Options:
--markdown          Store markdown for the image in the clipboard
--next <base_name>  Create the next available numbered file (e.g., "Saved 03.png")
                    Supports 2-digit indexes (01-99)
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help
while [[ "$1" =~ ^-- ]]; do
	if [[ "$1" == "--markdown" ]]; then
		storing_markdown=true
		shift
	elif [[ "$1" == "--next" ]]; then
		shift
		if [[ $# -eq 0 ]]; then
			echo "Error: --next option requires a base name" >&2
			exit 1
		fi
		
		base_name="$1"
		
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
	else
		shift
	fi
done

if [[ -z "$png_path" ]]; then
	png_path="$1"
	[[ -z "$png_path" ]] && help
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

if [[ -n "storing_markdown" ]]; then
	if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
		clip_app=clip.exe
	elif [[ "$ROPERDOT_DESKTOP_ENV" = "mac" ]]; then
		clip_app=pbcopy
	else
		clip_app="xclip -selection clipboard"
	fi
	name="${png_path%.*}"
	echo "<img src=\"./images/${png_path}\" alt=\"${name}\" align=\"left\"/>" | $clip_app
fi
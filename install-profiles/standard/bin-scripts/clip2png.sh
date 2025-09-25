#
# Description: Saves an image in the clipboard as a PNG file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -lt 1 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
clip2png: save an image in the clipboard as a PNG file
Usage: clip2png <output_file>
EOT
#'
	exit 0
fi
png_path="$1"
[[ "$png_path" == *".png" ]] || png_path="${png_path}.png"

if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
	powershell.exe -command "
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
\$img = Get-Clipboard -Format Image
if (\$img) {
    \$img.Save('$(wslpath -w "$png_path")', [System.Drawing.Imaging.ImageFormat]::Png)
    \$img.Dispose()
}
"
elif [[ "$ROPERDOT_DESKTOP_ENV" = "mac" ]]; then
	pngpaste "$png_path" 2>/dev/null
else
	xclip -selection clipboard -t image/png -o > "$png_path" 2>/dev/null
fi
#
# Description: (Windows) Configures Windows Console Host settings for WSL
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
configure-windows-console
Usage: configure-windows-console

This script configures the legacy Windows Console Host that's used when opening
Ubuntu directly (not through Windows Terminal). It sets the font to Hack Nerd Font
and applies color scheme settings to match Windows Terminal.
EOT
    exit 0
fi

if [[ "$ROPERDOT_DESKTOP_ENV" != "windows" ]]; then
    echo "This script only runs on Windows"
    exit 0
fi

echo "Configuring Windows Console Host for WSL..."

# Registry path for WSL console
console_key="HKCU\\Console\\%SystemRoot%_System32_wsl.exe"

font_name="Hack Nerd Font"

# Font size: high word = height, low word = width (0 = auto width)
# Size 11 = 0x000b0000 in hex, which is decimal 720896
font_size=720896

# Font family: 0x36 = FF_MODERN | FIXED_PITCH
font_family=54

# Font weight: 400 = normal
font_weight=400

echo "Setting font to $font_name, size 11..."

# Set font face name
reg.exe add "$console_key" /v FaceName /t REG_SZ /d "$font_name" /f >/dev/null 2>&1

# Set font size (11pt)
reg.exe add "$console_key" /v FontSize /t REG_DWORD /d $font_size /f >/dev/null 2>&1

# Set font family
reg.exe add "$console_key" /v FontFamily /t REG_DWORD /d $font_family /f >/dev/null 2>&1

# Set font weight
reg.exe add "$console_key" /v FontWeight /t REG_DWORD /d $font_weight /f >/dev/null 2>&1

echo "Setting color scheme..."

# Color scheme based on Roperdot hybrid
# These are COLORREF values (0x00BBGGRR format)

# Standard colors (indices 0-15)
reg.exe add "$console_key" /v ColorTable00 /t REG_DWORD /d 0x001c1c1c /f >/dev/null 2>&1  # Black
reg.exe add "$console_key" /v ColorTable01 /t REG_DWORD /d 0x000000cd /f >/dev/null 2>&1  # Dark Blue
reg.exe add "$console_key" /v ColorTable02 /t REG_DWORD /d 0x0000cd00 /f >/dev/null 2>&1  # Dark Green
reg.exe add "$console_key" /v ColorTable03 /t REG_DWORD /d 0x0000cdcd /f >/dev/null 2>&1  # Dark Cyan
reg.exe add "$console_key" /v ColorTable04 /t REG_DWORD /d 0x00cd0000 /f >/dev/null 2>&1  # Dark Red
reg.exe add "$console_key" /v ColorTable05 /t REG_DWORD /d 0x00cd00cd /f >/dev/null 2>&1  # Dark Magenta
reg.exe add "$console_key" /v ColorTable06 /t REG_DWORD /d 0x00cdcd00 /f >/dev/null 2>&1  # Dark Yellow
reg.exe add "$console_key" /v ColorTable07 /t REG_DWORD /d 0x00c5c1b4 /f >/dev/null 2>&1  # Gray
reg.exe add "$console_key" /v ColorTable08 /t REG_DWORD /d 0x00404040 /f >/dev/null 2>&1  # Dark Gray
reg.exe add "$console_key" /v ColorTable09 /t REG_DWORD /d 0x000000ff /f >/dev/null 2>&1  # Blue
reg.exe add "$console_key" /v ColorTable10 /t REG_DWORD /d 0x0000ff00 /f >/dev/null 2>&1  # Green
reg.exe add "$console_key" /v ColorTable11 /t REG_DWORD /d 0x0000ffff /f >/dev/null 2>&1  # Cyan
reg.exe add "$console_key" /v ColorTable12 /t REG_DWORD /d 0x00ff0000 /f >/dev/null 2>&1  # Red
reg.exe add "$console_key" /v ColorTable13 /t REG_DWORD /d 0x00ff00ff /f >/dev/null 2>&1  # Magenta
reg.exe add "$console_key" /v ColorTable14 /t REG_DWORD /d 0x00ffff00 /f >/dev/null 2>&1  # Yellow
reg.exe add "$console_key" /v ColorTable15 /t REG_DWORD /d 0x00ffffff /f >/dev/null 2>&1  # White

# Screen colors (background and foreground)
# Format: 0x00000000 where high byte = background, low byte = foreground
# Background: 0 (black), Foreground: 7 (gray)
reg.exe add "$console_key" /v ScreenColors /t REG_DWORD /d 0x00000007 /f >/dev/null 2>&1

# Popup colors
reg.exe add "$console_key" /v PopupColors /t REG_DWORD /d 0x000000f5 /f >/dev/null 2>&1

# Window size and buffer
# QuickEdit and Insert mode
reg.exe add "$console_key" /v QuickEdit /t REG_DWORD /d 1 /f >/dev/null 2>&1
reg.exe add "$console_key" /v InsertMode /t REG_DWORD /d 1 /f >/dev/null 2>&1

# Screen buffer size (width x height) - 120x9999
reg.exe add "$console_key" /v ScreenBufferSize /t REG_DWORD /d 0x270f0078 /f >/dev/null 2>&1

# Window size (width x height) - 120x30
reg.exe add "$console_key" /v WindowSize /t REG_DWORD /d 0x001e0078 /f >/dev/null 2>&1

echo "Successfully configured Windows Console Host"
echo "Changes will take effect the next time you open Ubuntu directly"

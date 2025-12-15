#
# Description: (Windows) Imports schemes into Windows Terminal settings and sets the current scheme
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
configure-windows-terminal
Usage: configure-windows-terminal

This script imports the schemes in roperdot/config/color-schemes/windows_terminal into
the Windows Terminal settings.json, and sets the scheme based on the value of
ROPERDOT_COMMON_COLOR_SCHEME.
EOT
    exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/windows-terminal-functions"

echo "Importing Roperdot color schemes into Windows Terminal settings..."

if ! terminal_settings_file="$(windows_terminal_settings_location)"; then
    echo "Windows Terminal settings file not found"
	exit 1
fi

color_schemes_dir="${ROPERDOT_DIR}/config/color-schemes/windows_terminal"

temp_settings=$(mktemp)

# Start with the current settings, ensuring schemes array exists
if ! /usr/bin/jq '.schemes //= []' "$terminal_settings_file" > "$temp_settings"; then
    echo "Error: Failed to read Windows Terminal settings file"
    rm -f "$temp_settings"
    exit 1
fi

# Process each color scheme file
for scheme_file in "$color_schemes_dir"/*.json; do
    if [[ -f "$scheme_file" ]]; then
        scheme_name=$(basename "$scheme_file" .json)

        # Read the scheme JSON
        scheme_json=
        if ! scheme_json=$(cat "$scheme_file"); then
            echo "Warning: Failed to read $scheme_file, skipping..."
            continue
        fi

        # Check if scheme already exists in settings
        scheme_display_name=$(/usr/bin/jq -r '.name' "$scheme_file")
		existing_scheme_index=$(/usr/bin/jq --arg name "$scheme_display_name" '.schemes | to_entries[] | select(.value.name == $name) | .key' "$temp_settings")
        
        if [[ -n "$existing_scheme_index" ]]; then
            # Update existing scheme
            if /usr/bin/jq --argjson scheme "$scheme_json" --argjson index "$existing_scheme_index" '.schemes[$index] = $scheme' "$temp_settings" > "${temp_settings}.tmp"; then
                mv "${temp_settings}.tmp" "$temp_settings"
                echo "Updated scheme $scheme_name"
            fi
        else
            # Add new scheme
            if /usr/bin/jq --argjson scheme "$scheme_json" '.schemes += [$scheme]' "$temp_settings" > "${temp_settings}.tmp"; then
                mv "${temp_settings}.tmp" "$temp_settings"
                echo "Added scheme $scheme_name"
            fi
        fi
    fi
done

# Validate the final JSON
if ! /usr/bin/jq empty "$temp_settings" 2>/dev/null; then
    echo "Error: Generated settings file is not valid JSON"
    rm -f "$temp_settings"
    exit 1
fi

# Create backup of original settings
backup_file="${terminal_settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
if ! cp "$terminal_settings_file" "$backup_file"; then
    echo "Warning: Failed to create backup of settings file"
else
    echo "Created backup: $backup_file"
fi

# Replace the original settings file
if mv "$temp_settings" "$terminal_settings_file"; then
    echo "Successfully imported color schemes into Windows Terminal"
else
    echo "Error: Failed to update Windows Terminal settings file"
    # Try to restore from backup if it exists
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$terminal_settings_file"
        echo "Restored original settings from backup"
    fi
    exit 1
fi

# Clean up temp file if it still exists
rm -f "$temp_settings"

if [[ "$ROPERDOT_COMMON_COLOR_SCHEME" == default ]]; then
	target_scheme="Roperdot ${ROPERDOT_DEFAULT_COMMON_COLOR_SCHEME}"
else
	target_scheme="Roperdot ${ROPERDOT_COMMON_COLOR_SCHEME}"
fi
# Update both defaults AND all Ubuntu profiles (there may be duplicates)
if /usr/bin/jq --arg scheme "$target_scheme" '
    .profiles.defaults.colorScheme = $scheme |
    .profiles.list[] |= if .name == "Ubuntu" and .hidden != true then 
        .colorScheme = $scheme | 
        .font = {"face": "Hack Nerd Font", "size": 11} 
    else . end
' "$terminal_settings_file" > tmp_terminal.json; then
    \mv tmp_terminal.json "$terminal_settings_file"
else
    echo "Failed to update Windows Terminal scheme"
    exit 1
fi
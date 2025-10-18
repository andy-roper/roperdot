#
# Description: (Windows) Sets the default profile for Windows Terminal
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
set-windows-terminal-default-profile
Usage: set-windows-terminal-default-profile [profile_name]

This script sets the default profile in Windows Terminal.
If a profile name is not supplied, it will default to Ubuntu.
EOT
    exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/windows-terminal-functions"

# Function to get WSL distribution GUID
get_wsl_guid() {
    local distro_name="$1"
    local settings_file="$2"
    
    if [[ -f "$settings_file" ]]; then
        # Extract GUID for the specified WSL distribution, excluding hidden profiles
        jq -r ".profiles.list[] | select(.name == \"$distro_name\" and .source == \"Microsoft.WSL\" and (.hidden != true)) | .guid" "$settings_file" 2>/dev/null | head -1
    fi
}

# Function to set WSL profile as default
set_wsl_as_default() {
    local settings_file="$1"
    local distro_name="$2"
    
    # Get the WSL GUID
    local wsl_guid=$(get_wsl_guid "$distro_name" "$settings_file")
    if [[ -z "$wsl_guid" ]]; then
        echo "Error: Could not find WSL profile for $distro_name"
        echo "Make sure Windows Terminal has detected your WSL distribution."
        exit 1
    fi
    
    echo "Setting $distro_name WSL profile as default..."
    
    # Backup and update
    cp "$settings_file" "$settings_file.backup.$(date +%Y%m%d_%H%M%S)"
    local temp_file=$(mktemp)
    
    # Set WSL profile as default
    jq --arg guid "$wsl_guid" '.defaultProfile = $guid' "$settings_file" > "$temp_file"
    mv "$temp_file" "$settings_file"
    
    echo "Successfully set $distro_name WSL profile as the default Windows Terminal profile."
    echo "Backup saved to: ${settings_file}.backup.*"
}

# Main execution
main() {
    local distro_name="${1:-Ubuntu}"
    echo "Setting $distro_name WSL profile as default Windows Terminal profile..."
    
    local settings_file
    if settings_file="$(windows_terminal_settings_location)"; then
        echo "Found settings file: $settings_file"
        set_wsl_as_default "$settings_file" "$distro_name"
        echo ""
        echo "Windows Terminal configuration updated!"
        echo "Please restart Windows Terminal to see the changes."
    else
        echo "Error: Could not find Windows Terminal settings file."
        echo "Make sure Windows Terminal has been run at least once."
        exit 1
    fi
}

main "$@"

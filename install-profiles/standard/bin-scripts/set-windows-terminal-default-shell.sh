#
# Description: (Windows) Sets default shell for Windows Terminal
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
set-windows-terminal-default-shell
Usage: set-windows-terminal-default-shell <shell>

This script sets the default terminal shell for Windows Terminal.

Example:
set-windows-terminal-default-shell zsh
EOT
    exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/win-env-functions"

find_wt_settings() {
	local localappdata_wsl="$(win_env_linux_path LOCALAPPDATA)"

	local terminal_settings_file="${localappdata_wsl}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

	if [[ ! -f "$terminal_settings_file" ]]; then
	    terminal_settings_file="${localappdata_wsl}/Microsoft/Windows Terminal/settings.json"
	fi
    
    if [[ -f "$terminal_settings_file" ]]; then
    	echo $terminal_settings_file
    else
        return 1
    fi
}

# Function to get WSL distribution GUID
get_wsl_guid() {
    local distro_name="$1"
    local userprofile_wsl="$(win_env_linux_path USERPROFILE)"
    local settings_file="$userprofile_wsl/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    
    if [[ -f "$settings_file" ]]; then
        # Extract GUID for the specified WSL distribution
        jq -r ".profiles.list[] | select(.name == \"$distro_name\" or .source == \"Windows.Terminal.Wsl\") | .guid" "$settings_file" 2>/dev/null | head -1
    fi
}

# Function to create or update Windows Terminal profile for shell
setup_shell_profile() {
    local settings_file="$1"
    local shell="$2"
    local distro_name=$(wsl.exe -l -v | grep -E "^\*" | awk '{print $2}' | tr -d '\0' || echo "Ubuntu")
    
    cp "$settings_file" "$settings_file.backup.$(date +%Y%m%d_%H%M%S)"
    local temp_file=$(mktemp)
    
    # Get current WSL GUID or create new one
    local wsl_guid=$(get_wsl_guid "$distro_name")
    if [[ -z "$wsl_guid" ]]; then
        wsl_guid="{$(uuidgen)}"
    fi
    
    # Update settings to include shell profile and set it as default
    jq --arg guid "$wsl_guid" --arg distro "$distro_name" --arg shell "$shell" '
    # Add or update the shell profile
    .profiles.list |= map(
        if .guid == $guid or (.name == $distro and .source == "Windows.Terminal.Wsl") then
            . + {
                "commandline": "wsl.exe ~ -e $shell",
                "name": ($distro + " ($shell)"),
                "startingDirectory": "//wsl$/\($distro)/home/\(env.USER)"
            }
        else
            .
        end
    ) |
    # If no existing profile was updated, add a new one
    if (.profiles.list | map(select(.guid == $guid)) | length) == 0 then
        .profiles.list += [{
            "guid": $guid,
            "name": ($distro + " ($shell)"),
            "commandline": "wsl.exe ~ -e $shell",
            "source": "Windows.Terminal.Wsl",
            "startingDirectory": "//wsl$/\($distro)/home/\(env.USER)",
            "icon": "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png"
        }]
    else
        .
    end |
    # Set this profile as the default
    .defaultProfile = $guid
    ' "$settings_file" > "$temp_file"
    
    # Replace original file with updated version
    mv "$temp_file" "$settings_file"
    
    echo "Successfully updated Windows Terminal settings:"
    echo "- Added/updated $shell profile for $distro_name"
    echo "- Set $shell profile as default"
    echo "- Backup saved to: ${settings_file}.backup.*"
}

# Main execution
main() {
	local shell="$1"
    echo "Setting up $shell as default shell in Windows Terminal..."
    
    local settings_file
    if settings_file=$(find_wt_settings); then
        echo "Found settings file: $settings_file"
        setup_shell_profile "$settings_file" "$shell"
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
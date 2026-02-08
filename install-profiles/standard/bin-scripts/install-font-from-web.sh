#
# Description: Installs fonts from a web archive
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

# set -e

usage() {
	cat <<EOT
Usage: $0 <font_display_name> <font_family> <download_url> <check_filename>

Arguments:
  font_display_name  - Human readable name (e.g. 'Hack Nerd Font')
  font_family        - Font family name for grep/dirs (e.g. 'Hack')
  download_url       - Direct download URL for the font archive
  check_filename     - Filename to check if installed (e.g. 'HackNerdFont-Regular.ttf')

Example:
  $0 'Hack Nerd Font' 'Hack' 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz' 'HackNerdFontMono-Regular.ttf'
EOT
    exit 1
}

# Check arguments
[[ $# -ne 4 ]] && usage

# Parameters
FONT_NAME="$1"
FONT_FAMILY="$2"
DOWNLOAD_URL="$3"
CHECK_FILENAME="$4"

TEMP_DIR="$(mktemp -d)"

NC='\033[0m' # No Color

if [[ "$ROPERDOT_DESKTOP_ENV" = windows ]]; then
	. "${ROPERDOT_DIR}/source-scripts/win-env-functions"
	localappdata=$(win_env_linux_path LOCALAPPDATA)
	userprofile=$(win_env_linux_path USERPROFILE)
fi

log_info() { echo -e "${COLOR_BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${COLOR_YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${COLOR_RED}[ERROR]${NC} $1"; }

is_font_installed() {
    case "$ROPERDOT_DESKTOP_ENV" in
        "windows")
            # Check Windows per-user font directories first, then system
            [[ -f "${localappdata}/Microsoft/Windows/Fonts/$CHECK_FILENAME" ]] && return 0
            [[ -f "${userprofile}/AppData/Local/Microsoft/Windows/Fonts/$CHECK_FILENAME" ]] && return 0
            [[ -f "/c/Windows/Fonts/$CHECK_FILENAME" ]] && return 0
            ;;
        "mac")
            # Check macOS font directories
            [[ -f ~/Library/Fonts/$CHECK_FILENAME ]] && return 0
            [[ -f /Library/Fonts/$CHECK_FILENAME ]] && return 0
            ;;
        *)
            # Check using fc-list first
            if command -v fc-list >/dev/null 2>&1; then
                fc-list | grep -i "${FONT_FAMILY}" >/dev/null 2>&1 && return 0
            fi
            # Check common font directories
            [[ -f ~/.local/share/fonts/$CHECK_FILENAME ]] && return 0
            [[ -f ~/.fonts/$CHECK_FILENAME ]] && return 0
            [[ -f /usr/share/fonts/truetype/*/$CHECK_FILENAME ]] && return 0
            [[ -f /usr/local/share/fonts/$CHECK_FILENAME ]] && return 0
            ;;
    esac
    return 1
}

get_font_dir() {
    case "$ROPERDOT_DESKTOP_ENV" in
        "windows")
            # Always use per-user font directory (no admin required)
            echo "${localappdata}/Microsoft/Windows/Fonts"
            ;;
        "mac")
            echo "$HOME/Library/Fonts"
            ;;
        *)
            if [[ -d "$HOME/.fonts" ]] && [[ -n "$(find "$HOME/.fonts" -name "*.ttf" -o -name "*.otf" 2>/dev/null | head -1)" ]]; then
                echo "$HOME/.fonts"
            else
                echo "$HOME/.local/share/fonts"
            fi
            ;;
    esac
}

# Function to find font files in extracted directory
find_font_files_dir() {
    local temp_dir="$1"
    
    # Check if fonts are directly in temp dir
    if [[ -n "$(find "$temp_dir" -maxdepth 1 -name "*.ttf" -o -name "*.otf" 2>/dev/null | head -1)" ]]; then
        echo "$temp_dir"
        return
    fi
    
    # Look for subdirectories with font family name
    for pattern in "$FONT_FAMILY" "${FONT_FAMILY}*"; do
        if [[ -d "$temp_dir/$pattern" ]]; then
            echo "$temp_dir/$pattern"
            return
        fi
    done
    
    # Look for any subdirectory with font files
    for dir in "$temp_dir"/*; do
        if [[ -d "$dir" && -n "$(find "$dir" -name "*.ttf" -o -name "*.otf" 2>/dev/null | head -1)" ]]; then
            echo "$dir"
            return
        fi
    done
    
    echo "$temp_dir"
}

# Function to convert font filename to display name for Windows registry
get_font_display_name() {
    local filename="$1"
    local basename="${filename%.*}"  # Remove extension
    
    # Replace common patterns and add spaces
    local display_name="$basename"
    display_name="${display_name//NerdFont/ Nerd Font}"
    display_name="${display_name//Font/ Font}"
    display_name="${display_name//-/ }"
    display_name="${display_name//_/ }"
    
    # Handle common style suffixes
    display_name="${display_name// Regular/ Regular}"
    display_name="${display_name// Bold/ Bold}"
    display_name="${display_name// Italic/ Italic}"
    display_name="${display_name// Light/ Light}"
    display_name="${display_name// Medium/ Medium}"
    display_name="${display_name// SemiBold/ SemiBold}"
    display_name="${display_name// BoldItalic/ Bold Italic}"

    # Remove multiple spaces
    display_name=$(echo "$display_name" | sed 's/  */ /g')
    
    echo "$display_name"
}

# Function to register fonts in Windows registry (per-user)
register_windows_fonts() {
    local font_dir="$1"
    local installed_files=("${@:2}")
    
    if [[ "$ROPERDOT_DESKTOP_ENV" != "windows" ]]; then
        return 0
    fi
    
    if ! command -v reg.exe >/dev/null 2>&1; then
        log_warning "reg.exe not found - fonts copied but not registered in registry"
        return 0
    fi
    
    # Convert WSL font directory to Windows path for registry
    local windows_font_dir
    windows_font_dir=$(wslpath -w "$font_dir")
    
    # Always use per-user registry
    local registry_hive="HKCU"
    local registry_path="SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"
    
    log_info "Registering fonts in Windows user registry..."
    local registered_count=0
    
    # Register each font file
    for font_file in "${installed_files[@]}"; do
        local filename=$(basename "$font_file")
        local registry_value="$filename"
        local font_type="(TrueType)"
        
        # Get font subfamily (style) from filename as fallback
        local style_from_filename=""
        if [[ "$filename" =~ -Bold.*Italic ]]; then
            style_from_filename="Bold Italic"
        elif [[ "$filename" =~ -BoldItalic ]]; then
            style_from_filename="Bold Italic"
        elif [[ "$filename" =~ -Bold ]]; then
            style_from_filename="Bold"
        elif [[ "$filename" =~ -Italic ]]; then
            style_from_filename="Italic"
        elif [[ "$filename" =~ -Regular ]]; then
            style_from_filename="Regular"
        fi
        
        # Get the actual font family name from the TTF file using PowerShell
        local display_name=""
        if command -v powershell.exe >/dev/null 2>&1; then
            local family_name=$(powershell.exe -NoProfile -Command "
                \$fontFile = \"\$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts\\$filename\"
                Add-Type -AssemblyName System.Drawing
                \$fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
                \$fontCollection.AddFontFile(\$fontFile)
                \$fontCollection.Families[0].Name
            " 2>/dev/null | tr -d '\r')
            
            if [[ -n "$family_name" && -n "$style_from_filename" ]]; then
                if [[ "$style_from_filename" == "Regular" ]]; then
                    display_name="$family_name"
                else
                    display_name="$family_name $style_from_filename"
                fi
            fi
        fi
        
        # Fallback to filename-based name if PowerShell extraction failed
        if [[ -z "$display_name" ]]; then
            display_name=$(get_font_display_name "$filename")
            log_warning "Could not extract font info from $filename, using: $display_name"
        fi
        
        # Add to Windows registry
        if reg.exe add "$registry_hive\\$registry_path" /v "$display_name $font_type" /t REG_SZ /d "$registry_value" /f >/dev/null 2>&1; then
            log_info "Registered: $display_name"
            ((registered_count++))
        else
            log_warning "Failed to register: $display_name"
        fi
    done
    
    if [[ $registered_count -gt 0 ]]; then
        log_success "Registered $registered_count fonts in user registry"
        
        # Register fonts with Windows using Shell.Application COM object
        # This is what Windows Font Settings uses internally and properly registers per-user fonts
        log_info "Registering fonts with Windows font system..."
        if command -v powershell.exe >/dev/null 2>&1; then
            # Build list of font filenames to register
            # Only register Regular variants - Bold/Italic variants cause "not a valid font" errors
            local font_filenames=()
            for font_file in "${installed_files[@]}"; do
                local filename=$(basename "$font_file")
                # Only include Regular variants
                if [[ "$filename" =~ -Regular\. ]]; then
                    font_filenames+=("$filename")
                fi
            done
            
            # Build PowerShell script to register only the newly installed fonts
            local ps_script="
                \$ErrorActionPreference = 'SilentlyContinue'
                \$fontDir = \"\$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts\"
                \$shell = New-Object -ComObject Shell.Application
                \$fontsFolder = \$shell.Namespace(0x14)  # CSIDL_FONTS
                
                # Only process the fonts we just installed
                \$fontFiles = @(
                    $(printf '"%s",' "${font_filenames[@]}" | sed 's/,$//')
                )
                
                \$successCount = 0
                foreach (\$filename in \$fontFiles) {
                    \$fontPath = Join-Path \$fontDir \$filename
                    if (Test-Path \$fontPath) {
                        try {
                            # CopyHere triggers Windows font registration even though file already exists
                            # 0x10 = FOF_SILENT, 0x4 = FOF_NOCONFIRMATION
                            \$fontsFolder.CopyHere(\$fontPath, 0x14)
                            \$successCount++
                        } catch {
                            # Ignore errors - font may already be registered
                        }
                    }
                }
                
                Write-Output \"Registered \$successCount fonts\"
            "
            
            local result=$(powershell.exe -NoProfile -Command "$ps_script" 2>/dev/null | tail -1)
            log_success "$result with Windows font system"
            
            # Also broadcast WM_FONTCHANGE for good measure
            powershell.exe -NoProfile -Command "
                \$signature = '[DllImport(\"user32.dll\", SetLastError=true, CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);'
                \$type = Add-Type -MemberDefinition \$signature -Name FontNotify -Namespace Win32 -PassThru
                \$result = [IntPtr]::Zero
                \$type::SendMessageTimeout(0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]\$result) | Out-Null
            " >/dev/null 2>&1
        else
            log_warning "PowerShell not available - may need to log out/in to see fonts"
        fi
    fi

    if [[ ! -d ~/.local/share/fonts ]]; then
    	echo "Creating symlink to Fonts directory"
    	[[ -d ~/.local/share ]] || mkdir ~/.local/share
    	ln -s "${localappdata}/Microsoft/Windows/Fonts" ~/.local/share/fonts
    fi
    log_info "Updating font cache..."
    fc-cache -fv
    log_success "Font cache updated"
}

# Function to extract and install fonts
install_fonts() {
    local font_files_dir="$1"
    local font_dir="$2"
    
    log_info "Creating font directory: $font_dir"
    mkdir -p "$font_dir"
    
    log_info "Installing font files..."
    local installed_count=0
    local installed_files=()
    
    # Copy all .ttf and .otf files
    for font_file in "$font_files_dir"/*.ttf "$font_files_dir"/*.otf; do
        if [[ -f "$font_file" ]]; then
            local filename=$(basename "$font_file")
            local dest_file="$font_dir/$filename"
            
            # Check if font already exists
            if [[ -f "$dest_file" ]]; then
                log_info "Already exists: $filename"
                continue
            fi
            
            if cp "$font_file" "$dest_file" 2>/dev/null; then
                log_info "Installed: $filename"
                installed_files+=("$dest_file")
                ((installed_count++))
            else
                log_warning "Failed to copy: $filename"
            fi
        fi
    done
    
    if [[ $installed_count -eq 0 ]]; then
        log_error "No font files found to install"
        return 1
    fi
    
    log_success "Installed $installed_count font files"
    
    # Platform-specific post-installation
    case "$ROPERDOT_DESKTOP_ENV" in
        "windows")
            register_windows_fonts "$font_dir" "${installed_files[@]}"
            ;;
        *)
            if command -v fc-cache >/dev/null 2>&1; then
                log_info "Updating font cache..."
                fc-cache -fv
                log_success "Font cache updated"
            fi
            ;;
    esac
}

main() {
    log_info "Installing $FONT_NAME..."
    
    # Check if already installed
    if is_font_installed; then
        log_success "$FONT_NAME appears to be already installed"
        read -p "Reinstall anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation skipped"
            exit 0
        fi
    fi

    # Get font installation directory
    FONT_DIR=$(get_font_dir)
    log_info "Font directory: $FONT_DIR"
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Cleanup function
    cleanup() {
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    }
    trap cleanup EXIT
    
    # Download font archive
    log_info "Downloading $FONT_NAME..."
    local archive_name=$(basename "$DOWNLOAD_URL")
    local archive_file="$TEMP_DIR/$archive_name"
    
    if ! get-web-file "$DOWNLOAD_URL" "$archive_file"; then
        log_error "Failed to download font archive"
        exit 1
    fi
    
    # Extract archive
    log_info "Extracting font archive..."
    if ! x "$archive_file" "$TEMP_DIR"; then
        exit 1
    fi

	find "$TEMP_DIR" -type f -name "*.ttf" | head -20

    # Find the font files directory
    local font_files_dir=$(find_font_files_dir "$TEMP_DIR")
    log_info "Font files found in: $font_files_dir"
    
    install_fonts "$font_files_dir" "$FONT_DIR"
    
    # Platform-specific post-installation
    case "$ROPERDOT_DESKTOP_ENV" in
        "mac")
            log_info "Note: You may need to restart applications to see the new font"
            ;;
        "windows")
            log_info "Note: You may need to restart applications or log out/in to see the new font"
            ;;
    esac
    
    log_success "$FONT_NAME installation completed!"
    
    # if is_font_installed; then
    #     log_success "Font installation verified successfully"
    # else
    #     log_warning "Font installation verification failed, but files were copied"
    # fi
}

if [[ -z "$ROPERDOT_DESKTOP_ENV" ]]; then
    log_error "ROPERDOT_DESKTOP_ENV environment variable is not set"
    exit 1
fi

main "$@"
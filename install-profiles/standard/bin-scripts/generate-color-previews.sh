#
# Description: Generates a color preview file for each color scheme
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
generate-color-previews: generate a color preview file for each color scheme
Usage: generate-color-previews

This script generates a color preview file for use by fzf during the install
when selecting a color scheme.

A preview file per color scheme is generated as
color-schemes/source/*/preview.txt.
EOT
	exit 0
fi

declare -A color_names=(
    [BRGREEN]="Bright Green"
    [BRCYAN]="Bright Cyan"
    [BRBLUE]="Bright Blue"
    [BRYELLOW]="Bright Yellow"
    [BRRED]="Bright Red"
    [BRBLACK]="Bright Black"
    [CYAN]="Cyan"
    [BRWHITE]="Bright White"
    [GREEN]="Green"
    [RED]="Red"
    [MAGENTA]="Magenta"
    [BLACK]="Black"
    [BRMAGENTA]="Bright Magenta"
    [WHITE]="White"
    [YELLOW]="Yellow"
    [BLUE]="Blue"
)

# Order for display (two columns: normal colors, then bright colors)
normal_colors=(BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE)
bright_colors=(BRBLACK BRRED BRGREEN BRYELLOW BRBLUE BRMAGENTA BRCYAN BRWHITE)

hex_to_rgb() {
    local hex=$1
    # Remove any leading #
    hex=${hex#\#}
    
    # Convert hex to RGB
    printf "%d;%d;%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

generate_preview() {
    local scheme_dir=$1
    local scheme_name=$(basename "$scheme_dir")
    
    # Skip if required files don't exist
    [[ ! -f "$scheme_dir/initialize" ]] && return
    [[ ! -f "$scheme_dir/color-env-vars" ]] && return
    
    # Extract background color from initialize file
    local bg_hex=$(grep "^BACKGROUND_COLOR=" "$scheme_dir/initialize" | cut -d'"' -f2 | cut -d' ' -f1)
    
    # Convert background hex to RGB for ANSI
    local bg_rgb=$(hex_to_rgb "$bg_hex")
    
    # Source the color-env-vars to get color codes
    source "$scheme_dir/color-env-vars"
    
    # Create preview file
    local preview_file="$scheme_dir/preview.txt"
    
    # Build preview content with background color applied to each line
    {
        # Header with some spacing
        printf "\e[48;2;%sm%-60s\e[0m\n" "$bg_rgb" ""
        printf "\e[48;2;%sm  Color Scheme: %-44s\e[0m\n" "$bg_rgb" "$scheme_name"
        printf "\e[48;2;%sm%-60s\e[0m\n" "$bg_rgb" ""
        
        # Display colors in two columns
        for i in {0..7}; do
            local normal_color=${normal_colors[$i]}
            local bright_color=${bright_colors[$i]}
            
            # Get the color variables
            local normal_var="COLOR_${normal_color}"
            local bright_var="COLOR_${bright_color}"
            
            # Get color values (compatible with both bash and zsh)
            # Use eval for maximum compatibility
            local normal_val=$(eval echo \"\$$normal_var\")
            local bright_val=$(eval echo \"\$$bright_var\")
            
            # Get color names for display
            local normal_name="${color_names[$normal_color]}"
            local bright_name="${color_names[$bright_color]}"
            
            # Build the line with colors, background applied to whole line
            # Apply background throughout entire line, not just at start
            # Format: BG + spaces + FG color + name + BG (reapply) + spaces + FG color + name + BG + padding + reset
            printf "\e[48;2;%sm  %b%s\e[48;2;%sm  %b%s\e[48;2;%sm%-4s\e[0m\n" \
                "$bg_rgb" "$normal_val" "$(printf '%-26s' "$normal_name")" \
                "$bg_rgb" "$bright_val" "$(printf '%-26s' "$bright_name")" \
                "$bg_rgb" ""
        done
        
        printf "\e[48;2;%sm%-60s\e[0m\n" "$bg_rgb" ""
        
        # Add extra blank lines to fill preview pane (with background color)
        for i in {1..10}; do
            printf "\e[48;2;%sm%-60s\e[0m\n" "$bg_rgb" ""
        done
    } > "$preview_file"
    
    echo "Generated preview for: $scheme_name"
}

# Main execution
base_dir="${ROPERDOT_DIR:-$HOME/roperdot}/config/color-schemes/source"

if [[ ! -d "$base_dir" ]]; then
    echo "Error: Color schemes directory not found: $base_dir"
    exit 1
fi

echo -e "Generating color scheme previews...\n"

# Process each color scheme
for scheme_dir in "$base_dir"/*; do
    [[ -d "$scheme_dir" ]] || continue
    generate_preview "$scheme_dir"
done

echo -e "\nPreview generation complete!"

#
# Description: cd to a directory containing Java classes
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
_cdj: cd to a directory containing Java classes
Usage: _cdj

The _cdj script is called by the cdj function.

This script finds directories containing .java files and lets you select one.
It searches upward for 'src' or 'code' directory and searches from there.

Display format:
  - Within src tree: Shows package path
  - Within code tree: Shows path from "code" directory

Requirements: fzf
EOT
    exit 0
fi

set -e

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required but not installed" >&2
    exit 1
fi

# Find src or code directory by traversing up
find_root() {
    local current="$(pwd)"
    
    # First try to find 'src'
    while [[ "$current" != "/" ]]; do
        if [[ -d "$current/src" ]]; then
            echo "$current/src"
            return 0
        fi
        if [[ "$(basename "$current")" == "src" ]]; then
            echo "$current"
            return 0
        fi
        current="$(dirname "$current")"
    done
    
    # If src not found, try to find 'code'
    current="$(pwd)"
    while [[ "$current" != "/" ]]; do
        if [[ -d "$current/code" ]]; then
            echo "$current/code"
            return 0
        fi
        if [[ "$(basename "$current")" == "code" ]]; then
            echo "$current"
            return 0
        fi
        current="$(dirname "$current")"
    done
    
    return 1
}

# Find the root directory
ROOT=$(find_root)
if [[ -z "$ROOT" ]]; then
    echo "Error: Could not find 'src' or 'code' directory" >&2
    exit 1
fi

ROOT_BASENAME="$(basename "$ROOT")"

# Find all directories containing .java files
echo "Finding directories with Java classes under $ROOT..." >&2

# Find directories with .java files directly in them
JAVA_DIRS=$(find "$ROOT" -type f -name "*.java" -exec dirname {} \; | sort -u)

if [[ -z "$JAVA_DIRS" ]]; then
    echo "Error: No directories containing Java classes found" >&2
    exit 1
fi

# Build the display list with formatted paths
declare -a DISPLAY_PATHS
declare -a ACTUAL_PATHS

while IFS= read -r dir; do
    if [[ "$ROOT_BASENAME" == "src" ]]; then
        # Strip src/*/java/ prefix for display
        DISPLAY_PATH=$(echo "$dir" | sed -E 's|^.*/src/[^/]+/java/||')
    else
        # Show relative from code
        DISPLAY_PATH="${dir#$ROOT/}"
    fi
    
    DISPLAY_PATHS+=("$DISPLAY_PATH")
    ACTUAL_PATHS+=("$dir")
done <<< "$JAVA_DIRS"

# Get count for fzf height
COUNT=${#DISPLAY_PATHS[@]}
HEIGHT=$((COUNT + 2))
(( HEIGHT > LINES / 2 )) && HEIGHT=50%

# Show in fzf for selection (using cat -n for line numbers)
SELECTED_INDEX=$(printf "%s\n" "${DISPLAY_PATHS[@]}" | \
    cat -n | \
    fzf --with-nth=2.. --prompt="Select Java directory: " --layout=reverse -0 --height="$HEIGHT" | \
    awk '{print $1}')

[[ -z "$SELECTED_INDEX" ]] && exit 0

# Output the actual path (adjust for 0-based array indexing)
echo "${ACTUAL_PATHS[$((SELECTED_INDEX - 1))]}"

#
# Description: Allow selection of a directory containing Java classes
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
_cdj: Allow selection of a directory containing Java classes
Usage: _cdj [--build] [filter]

This script finds directories containing .java files or Makefiles and lets you select one.

The cached directory list is built from the 'code' directory.
If you're within a 'src' subdirectory, only directories under that src are shown.

Options:
  -a, --all     Find directories relative to code regardless of current directory
  -b, --build   Rebuild the directory cache
  filter        Optional case-insensitive filter for directory list

Display format:
  - Within src tree: Shows package path
  - Within code tree: Shows path from code

The directory list is cached at ~/.cache/cdj/dirs for performance. The cache is
is built from entire 'code' directory.

Additional directories:
  You can include additional directories (without .java files or Makefiles) by listing them in:
    ~/.config/cdj/additional-dirs.txt
  
  Format: One absolute path per line (tilde expansion supported, # for comments)
EOT
    exit 0
fi

# Cache file location
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/cdj/dirs"

# Additional directories config file
ADDITIONAL_DIRS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cdj/additional-dirs.txt"

# Parse arguments
REBUILD=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
    	-a|--all)
			SHOW_ALL=true
			shift
			;;
        -b|--build)
            REBUILD=true
            shift
            ;;
        *)
            FILTER="$1"
            shift
            ;;
    esac
done

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required but not installed" >&2
    exit 1
fi

# Find code directory by traversing up
find_code_root() {
    local current="$(pwd)"
    
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

# Find which src directory we're currently in (if any)
find_current_src() {
    local current="$(pwd)"
    
    while [[ "$current" != "/" ]]; do
        if [[ "$(basename "$current")" == "src" ]]; then
            echo "$current"
            return 0
        fi
        current="$(dirname "$current")"
    done
    
    return 1
}

# Check if we're within a src subdirectory
if [[ -z "$SHOW_ALL" ]]; then
	CURRENT_SRC=$(find_current_src) || true
fi

# Check if cache needs rebuilding
need_rebuild() {
    [[ "$REBUILD" == true ]] && return 0
    [[ ! -f "$CACHE_FILE" ]] && return 0
    return 1
}

# Build the directory cache (requires being in or under code directory)
build_cache() {
    # Find code root for building
    CODE_ROOT=$(find_code_root)
    if [[ -z "$CODE_ROOT" ]]; then
        echo "Error: Could not find 'code' directory. Must be within code tree to build cache." >&2
        exit 1
    fi
    
    echo "Building directory cache under $CODE_ROOT..." >&2
    
    # Find directories with .java files directly in them
    echo "Finding directories with .java files..." >&2
    JAVA_DIRS=$(find "$CODE_ROOT" -type f -name "*.java" -exec dirname {} \; | sort -u)
    
    # Find directories with Makefile
    echo "Finding directories with Makefile..." >&2
    MAKEFILE_DIRS=$(find "$CODE_ROOT" -type f -name "Makefile" -exec dirname {} \; | sort -u)
    
    # Combine java and makefile directories
    if [[ -n "$MAKEFILE_DIRS" ]]; then
        JAVA_DIRS=$(printf "%s\n%s" "$JAVA_DIRS" "$MAKEFILE_DIRS")
    fi
    
    # Add additional directories from config file if it exists
    echo "DEBUG: Checking for $ADDITIONAL_DIRS_FILE..." >&2
    if [[ -f "$ADDITIONAL_DIRS_FILE" ]]; then
        echo "Adding directories from $ADDITIONAL_DIRS_FILE..." >&2
        while IFS= read -r dir; do
            echo "DEBUG: Read line: '$dir'" >&2
            # Skip empty lines and comments
            [[ -z "$dir" || "$dir" == \#* ]] && continue
            
            # Expand tilde
            expanded_dir="${dir/#\~/$HOME}"
            echo "DEBUG: Expanded to: '$expanded_dir'" >&2
            
            # Only add if it exists and is under CODE_ROOT
            if [[ -d "$expanded_dir" ]]; then
                if [[ "$expanded_dir" == "$CODE_ROOT"* ]]; then
                    echo "  Adding: $expanded_dir" >&2
                    JAVA_DIRS=$(printf "%s\n%s" "$JAVA_DIRS" "$expanded_dir")
                else
                    echo "  Skipping (not under CODE_ROOT): $expanded_dir" >&2
                    echo "DEBUG: CODE_ROOT is: $CODE_ROOT" >&2
                fi
            else
                echo "  Skipping (not found): $expanded_dir" >&2
            fi
        done < "$ADDITIONAL_DIRS_FILE"
    else
        echo "DEBUG: File not found at $ADDITIONAL_DIRS_FILE" >&2
    fi
    
    # Sort and remove duplicates
    JAVA_DIRS=$(echo "$JAVA_DIRS" | sort -u)
    
    echo "Find completed, checking results..." >&2
    if [[ -z "$JAVA_DIRS" ]]; then
        echo "Error: No directories containing Java classes found" >&2
        exit 1
    fi
    
    # Save to cache with metadata
    echo "Creating cache directory..." >&2
    mkdir -p "$(dirname "$CACHE_FILE")"
    echo "Writing cache file to $CACHE_FILE..." >&2
    {
        echo "ROOT=$CODE_ROOT"
        echo "TIMESTAMP=$(date +%s)"
        echo "---"
        echo "$JAVA_DIRS"
    } > "$CACHE_FILE"
    
    echo "Cache built: $(echo "$JAVA_DIRS" | wc -l) directories found" >&2
}

# Load or build cache
if need_rebuild; then
    build_cache
    JAVA_DIRS=$(sed -n '/^---$/,$p' "$CACHE_FILE" | tail -n +2)
else
    # Load from cache
    if [[ -f "$CACHE_FILE" ]]; then
        JAVA_DIRS=$(sed -n '/^---$/,$p' "$CACHE_FILE" | tail -n +2)
    else
        echo "Error: Cache file not found (this shouldn't happen)" >&2
        exit 1
    fi
fi

# If we're within a src subdirectory, filter to only that src
if [[ -n "$CURRENT_SRC" ]]; then
    JAVA_DIRS=$(echo "$JAVA_DIRS" | grep "^$CURRENT_SRC/")
    if [[ -z "$JAVA_DIRS" ]]; then
        echo "Error: No Java directories found under $CURRENT_SRC" >&2
        exit 1
    fi
fi

# Apply additional text filter if provided
if [[ -n "$FILTER" ]]; then
    FILTERED_DIRS=$(echo "$JAVA_DIRS" | grep -i "$FILTER")
    
    if [[ -z "$FILTERED_DIRS" ]]; then
        echo "No directories match filter: '$FILTER'" >&2
        echo -n "Rebuild cache and try again? [y/N] " >&2
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            build_cache
            JAVA_DIRS=$(sed -n '/^---$/,$p' "$CACHE_FILE" | tail -n +2)
            
            # Re-apply src filter if needed
            if [[ -n "$CURRENT_SRC" ]]; then
                JAVA_DIRS=$(echo "$JAVA_DIRS" | grep "^$CURRENT_SRC/")
            fi
            
            FILTERED_DIRS=$(echo "$JAVA_DIRS" | grep -i "$FILTER")
            
            if [[ -z "$FILTERED_DIRS" ]]; then
                echo "Error: No directories match filter even after rebuild: '$FILTER'" >&2
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    JAVA_DIRS="$FILTERED_DIRS"
fi

if [[ -z "$JAVA_DIRS" ]]; then
    echo "Error: No directories found" >&2
    exit 1
fi

# Build the display list with formatted paths
declare -a DISPLAY_PATHS
declare -a ACTUAL_PATHS

while IFS= read -r dir; do
    if [[ -n "$CURRENT_SRC" ]]; then
        # Within src tree: Strip src/*/java/ prefix for display
        DISPLAY_PATH=$(echo "$dir" | sed -E 's|^.*/src/[^/]+/java/||')
    else
        # Get CODE_ROOT from cache for display formatting
        CACHED_ROOT=$(grep "^ROOT=" "$CACHE_FILE" | cut -d= -f2-)
        # Within code tree: Show relative from code
        DISPLAY_PATH="${dir#$CACHED_ROOT/}"
    fi
    
    DISPLAY_PATHS+=("$DISPLAY_PATH")
    ACTUAL_PATHS+=("$dir")
done <<< "$JAVA_DIRS"

# Get count for fzf height
COUNT=${#DISPLAY_PATHS[@]}
HEIGHT=$((COUNT + 2))
(( HEIGHT > LINES / 2 )) && HEIGHT=50%

# Show in fzf for selection (using cat -n for line numbers)
# --exact flag makes filtering consecutive/exact instead of fuzzy
SELECTED_INDEX=$(printf "%s\n" "${DISPLAY_PATHS[@]}" | \
    cat -n | \
    fzf --exact --with-nth=2.. --prompt="Select Java directory: " --layout=reverse -0 --height="$HEIGHT" | \
    awk '{print $1}')

[[ -z "$SELECTED_INDEX" ]] && exit 0

# Output the actual path (adjust for 0-based array indexing)
if [[ "$ROPERDOT_CURRENT_SHELL" == "zsh" ]]; then
    echo "${ACTUAL_PATHS[$SELECTED_INDEX]}"
else
    echo "${ACTUAL_PATHS[$((SELECTED_INDEX - 1))]}"
fi

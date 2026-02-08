#
# Description: Edit a Java class by searching for it
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
je: edit a Java class
Usage: je [OPTIONS] [directory] [pattern]

This script recursively searches for Java source files so you can open one in
an editor using the 'e' command. By default, only src/main/java are searched.

Options:
  -a, --all    Include test files (i.e. in src/test/java)

Arguments:
  directory    Optional directory to search (default: current directory)
  pattern      Search pattern for filename (case-insensitive)
EOT
    exit 0
fi

# Parse arguments
ALL_FLAG=false
SEARCH_DIR=""
PATTERN=""

for arg in "$@"; do
    case "$arg" in
        -a|--all)
            ALL_FLAG=true
            ;;
        *)
            # Check if this looks like a directory
            if [[ -d "$arg" || "$arg" == /* || "$arg" == ./* || "$arg" == ../* ]]; then
                if [[ -z "$SEARCH_DIR" ]]; then
                    SEARCH_DIR="$arg"
                fi
            else
                # Otherwise it's part of the pattern
                if [[ -z "$PATTERN" ]]; then
                    PATTERN="$arg"
                else
                    PATTERN="$PATTERN $arg"
                fi
            fi
            ;;
    esac
done

set -e

# Determine search directory (default to current)
SEARCH_DIR="${SEARCH_DIR:-.}"

# Expand ~ if present
SEARCH_DIR="${SEARCH_DIR/#\~/$HOME}"

if [[ ! -d "$SEARCH_DIR" ]]; then
    echo "Error: Directory not found: $SEARCH_DIR"
    exit 1
fi

# Build find command with exclusions
FIND_CMD="find \"$SEARCH_DIR\" -type f -name \"*.java\""

# Add exclusions for build directories
EXCLUSIONS=(
    "*/build/*"
    "*/target/*"
    "*/out/*"
    "*/.gradle/*"
    "*/bin/*"
)

if [[ "$ALL_FLAG" == false ]]; then
    EXCLUSIONS+="*/test/*"
fi

for excl in "${EXCLUSIONS[@]}"; do
    FIND_CMD="$FIND_CMD ! -path \"$excl\""
done

if [[ -z "$PATTERN" ]]; then
    echo "Searching for all Java files..."
    JAVA_FILES=$(eval "$FIND_CMD" | while read -r file; do
        # Convert to absolute path for consistent package inference
        if [[ "$file" == /* ]]; then
            echo "$file"
        else
            echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
        fi
    done | sort)
else
    echo "Searching for Java files matching '$PATTERN'..."
    # Use awk for fast filtering - much faster than a while loop with subprocesses
    JAVA_FILES=$(eval "$FIND_CMD" | awk -v pattern="$PATTERN" '
        BEGIN { IGNORECASE=1 }
        {
            # Extract filename from path
            n = split($0, parts, "/")
            filename = parts[n]
            if (index(filename, pattern) > 0) {
                print $0
            }
        }
    ' | while read -r file; do
        # Convert to absolute path for consistent package inference
        if [[ "$file" == /* ]]; then
            echo "$file"
        else
            echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
        fi
    done | sort)
fi

# Check if we found any files
if [[ -z "$JAVA_FILES" ]]; then
    echo "No Java files found matching the criteria"
    exit 0
fi

# Count matches
MATCH_COUNT=$(echo "$JAVA_FILES" | wc -l | tr -d ' ')

# Function to format file path as package.ClassName.java
format_display() {
    local file="$1"
    local package=""
    # Get class name without spawning basename subprocess
    local class_name="${file##*/}"
    
    # Fast path-based inference using string operations instead of regex
    # Look for '/java/' in the path
    if [[ "$file" == */java/* ]]; then
        # Extract everything after '/java/' and before the filename
        local after_java="${file#*/java/}"
        local dir_path="${after_java%/*}"
        # Convert slashes to dots
        package="${dir_path//\//.}"
    elif [[ "$file" == */src/* ]]; then
        # Fallback: extract from '/src/' onwards
        local after_src="${file#*/src/}"
        local dir_path="${after_src%/*}"
        package="${dir_path//\//.}"
    fi
    
    if [[ -n "$package" ]]; then
        echo "${package}.${class_name}"
    else
        echo "$class_name"
    fi
}

# Select file to edit
if [[ "$MATCH_COUNT" -eq 1 ]]; then
    # Single match - auto-select
    SELECTED_FILE="$JAVA_FILES"
    DISPLAY_NAME=$(format_display "$SELECTED_FILE")
    echo "Auto-selected: $DISPLAY_NAME"
else
    # Multiple matches - use gum or fzf
	typeset -a JAVA_PATHS
	DISPLAY_LIST=""
	INDEX=0

	while IFS= read -r file; do
	    [[ -z "$file" ]] && continue
	    
	    # Inline format_display logic for performance
	    local package=""
	    local class_name="${file##*/}"
	    
	    if [[ "$file" == */java/* ]]; then
	        local after_java="${file#*/java/}"
	        local dir_path="${after_java%/*}"
	        package="${dir_path//\//.}"
	    elif [[ "$file" == */src/* ]]; then
	        local after_src="${file#*/src/}"
	        local dir_path="${after_src%/*}"
	        package="${dir_path//\//.}"
	    fi
	    
	    if [[ -n "$package" ]]; then
	        display="${package}.${class_name}"
	    else
	        display="$class_name"
	    fi
	    
	    JAVA_PATHS+=("$file")
	    DISPLAY_LIST+="${display}|${INDEX}"$'\n'
	    INDEX=$((INDEX + 1))
	done <<< "$JAVA_FILES"

	# Preprocess to show only the display names (not the index)
	DISPLAY_ONLY=$(echo "$DISPLAY_LIST" | cut -d'|' -f1)

	if command -v gum >/dev/null 2>&1; then
		height=$(( LINES / 3 ))
		SELECTED_DISPLAY=$(echo "$DISPLAY_ONLY" | gum filter --height=$height --placeholder="Select Java class to edit...")
	else
		SELECTED_DISPLAY=$(echo "$DISPLAY_ONLY" | \
		    fzf --prompt="Select Java class to edit: " \
		        --exact \
		        --layout=reverse \
		        --height=33%)
	fi

	if [[ -z "$SELECTED_DISPLAY" ]]; then
	    echo "No file selected"
	    exit 0
	fi

	# Find the corresponding index from the full DISPLAY_LIST
	SELECTED_INDEX=$(echo "$DISPLAY_LIST" | grep -F "${SELECTED_DISPLAY}|" | head -1 | cut -d'|' -f2)
	
	# Handle array indexing differences between bash and zsh
	if [[ "$ROPERDOT_CURRENT_SHELL" = zsh ]]; then
		SELECTED_FILE="${JAVA_PATHS[$SELECTED_INDEX+1]}"  # zsh arrays are 1-indexed
	else
		SELECTED_FILE="${JAVA_PATHS[$SELECTED_INDEX]}"    # bash arrays are 0-indexed
	fi

	if [[ -z "$SELECTED_FILE" ]]; then
	    echo "Error: Could not resolve file path"
	    exit 1
	fi
fi

# Open file in editor using the 'e' command
echo "Opening: $SELECTED_FILE"
e "$SELECTED_FILE"

#
# Description: Parse Java stack trace and open files in VS Code at referenced lines
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
open-stack: Open Java stack trace files in VS Code

Usage: 
  open-stack              Read stack trace from clipboard
  open-stack <file>       Read stack trace from file
  cat stack.txt | open-stack   Read stack trace from stdin

The script will:
  1. Parse Java stack trace entries (lines starting with "at ")
  2. Extract fully qualified class names and line numbers
  3. Search for corresponding .java files in the current directory tree
  4. Open each file in VS Code at the specified line

Options:
  -u, --unique  Only open each file once (at first occurrence)
  -v, --verbose Show what files are being opened
EOT
	exit 0
fi

# Detect shell for associative array syntax
if [[ "$ROPERDOT_CURRENT_SHELL" = zsh ]]; then
	typeset -A OPENED_FILES
else
	declare -A OPENED_FILES
fi

# Parse options
UNIQUE_ONLY=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		-u|--unique)
			UNIQUE_ONLY=true
			shift
			;;
		-v|--verbose)
			VERBOSE=true
			shift
			;;
		-*)
			echo "Unknown option: $1" >&2
			exit 1
			;;
		*)
			break
			;;
	esac
done

# Determine input source
if [[ $# -eq 0 ]]; then
	# No arguments - try clipboard
	if command -v clippaste >/dev/null 2>&1; then
		INPUT=$(clippaste)
	else
		echo "Error: clippaste not found and no input file specified" >&2
		exit 1
	fi
elif [[ -f "$1" ]]; then
	# File argument
	INPUT=$(cat "$1")
elif [[ ! -t 0 ]]; then
	# Stdin
	INPUT=$(cat)
else
	echo "Error: File '$1' not found" >&2
	exit 1
fi

# Load shell-specific regex matching
. "${ROPERDOT_DIR}/source-scripts/re-match"

# Parse stack trace and open files
echo "$INPUT" | while IFS= read -r line; do
	# Match lines like: at com.example.ClassName.method(ClassName.java:123)
	if re_match "$line" '^[[:space:]]*at[[:space:]]+([a-zA-Z0-9_.]+)\.[^(]+\(([^:]+):([0-9]+)\)'; then
		QUALIFIED_CLASS="${re_match[1]}"
		SOURCE_FILE="${re_match[2]}"
		LINE_NUMBER="${re_match[3]}"
		
		# Convert package path to directory path: com.example.Foo -> com/example/Foo
		PACKAGE_PATH="${QUALIFIED_CLASS%.*}"  # Remove class name
		PACKAGE_PATH="${PACKAGE_PATH//./\/}"  # Convert dots to slashes
		
		# Search for the Java file
		# Look for files matching the package structure
		SEARCH_PATTERN="${PACKAGE_PATH}/${SOURCE_FILE}"
		
		if [[ "$VERBOSE" == true ]]; then
			echo "Searching for: $SEARCH_PATTERN (line $LINE_NUMBER)" >&2
		fi
		
		# Find the file (search from current directory down)
		FOUND_FILE=$(find . -type f -path "*/${SEARCH_PATTERN}" 2>/dev/null | head -n 1)
		
		if [[ -n "$FOUND_FILE" ]]; then
			# Check if we've already opened this file (for --unique mode)
			if [[ "$UNIQUE_ONLY" == true ]] && [[ -n "${OPENED_FILES[$FOUND_FILE]}" ]]; then
				if [[ "$VERBOSE" == true ]]; then
					echo "Skipping duplicate: $FOUND_FILE" >&2
				fi
				continue
			fi
			
			# Mark as opened
			OPENED_FILES[$FOUND_FILE]=1
			
			if [[ "$VERBOSE" == true ]]; then
				echo "Opening: $FOUND_FILE:$LINE_NUMBER" >&2
			fi
			
			# Open in VS Code at the specific line
			code --goto "${FOUND_FILE}:${LINE_NUMBER}"
		else
			if [[ "$VERBOSE" == true ]]; then
				echo "Not found: $SEARCH_PATTERN" >&2
			fi
		fi
	fi
done

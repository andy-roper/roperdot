#
# Description: Runs a gradle test
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

# Parse arguments for --all/-a flag and directory
ALL_FLAG=false
TEST_DIR=""

for arg in "$@"; do
    case "$arg" in
        --help|-h|-\?)
            cat <<EOT
gt: run a gradle test
Usage: gt [OPTIONS] [test-dir]

This script intelligently selects gradle tests to run. By default, if you're
in a directory containing test classes, it will use only those classes. Otherwise,
it searches recursively from the base directory.

Options:
  -a, --all     Force recursive search from base directory (ignore local classes)
  -h, --help    Show this help message

Behavior:
  - If current directory has test classes: Use only those (non-recursive)
    - Single class: Auto-select and jump to method selection
    - Multiple classes: Prompt for class selection
  - Otherwise: Search recursively from base directory
  - With --all: Always search recursively, ignore local classes

Base directory priority:
  1. Command-line argument [test-dir]
  2. GRADLE_TEST_DIR environment variable
  3. Current directory (.)

Environment variables:
  GRADLE_TEST_DIR  Base directory for test search
  GRADLE_MODULE    Gradle module to use (otherwise auto-detected)
EOT
            exit 0
            ;;
        -a|--all)
            ALL_FLAG=true
            ;;
        *)
            if [[ -z "$TEST_DIR" ]]; then
                TEST_DIR="$arg"
            fi
            ;;
    esac
done

set -e

# Determine base directory (priority: arg > env var > current dir)
TEST_DIR="${TEST_DIR:-${GRADLE_TEST_DIR:-.}}"

# Expand ~ if present
TEST_DIR="${TEST_DIR/#\~/$HOME}"

if [[ ! -d "$TEST_DIR" ]]; then
    echo "Error: Directory not found: $TEST_DIR"
    exit 1
fi

# Determine if we should use local (non-recursive) mode
LOCAL_MODE=false
if [[ "$ALL_FLAG" == false ]]; then
    # Check if current directory has .java files with @Test annotation
    if compgen -G "*.java" > /dev/null 2>&1; then
        if grep -l "@Test" *.java 2>/dev/null | grep -q .; then
            LOCAL_MODE=true
        fi
    fi
fi

# Find test class(es)
if [[ "$LOCAL_MODE" == true ]]; then
    # Non-recursive: use only test classes in current directory
    echo "Finding test classes in current directory..."
    
    # Find test files in current directory only
    LOCAL_TEST_FILES=$(find . -maxdepth 1 -type f \( -name "*Test.java" -o -name "*Tests.java" \) -exec grep -l "@Test" {} \; 2>/dev/null | sed 's|^\./||' | sort)
    
    if [[ -z "$LOCAL_TEST_FILES" ]]; then
        echo "No test classes found in current directory"
        exit 1
    fi
    
    # Count test files
    TEST_FILE_COUNT=$(echo "$LOCAL_TEST_FILES" | wc -l | tr -d ' ')
    
    if [[ "$TEST_FILE_COUNT" -eq 1 ]]; then
        # Single test class - auto-select it
        TEST_FILE="$LOCAL_TEST_FILES"
        echo "Auto-selected: $TEST_FILE"
    else
        # Multiple classes - let user choose
        TEST_FILE=$(echo "$LOCAL_TEST_FILES" | \
            fzf --prompt="Select test class: " --layout=reverse -0 --height=33%)
        
        if [[ -z "$TEST_FILE" ]]; then
            echo "No test selected"
            exit 0
        fi
    fi
    
    # Use current directory as base
    FULL_PATH="./$TEST_FILE"
    
else
    # Recursive mode: search from base directory
    echo "Finding test classes under $TEST_DIR..."
    TEST_FILE=$(find "$TEST_DIR" -type f \( -name "*Test.java" -o -name "*Tests.java" \) | \
        sort | \
        sed "s|^$TEST_DIR/||" | \
        fzf --prompt="Select test class: " --layout=reverse -0 --height=33%)
    
    if [[ -z "$TEST_FILE" ]]; then
        echo "No test selected"
        exit 0
    fi
    
    # Reconstruct full path
    FULL_PATH="$TEST_DIR/$TEST_FILE"
fi

# Extract package name from the Java file
PACKAGE=$(grep -m 1 "^package " "$FULL_PATH" | sed 's/package \(.*\);/\1/')

# Get just the class name (filename without .java)
CLASS_FILE=$(basename "$TEST_FILE")
CLASS_SIMPLE="${CLASS_FILE%.java}"

# Build fully qualified class name
CLASS_NAME="$PACKAGE.$CLASS_SIMPLE"

# Extract test methods (portable version - works with BSD and GNU grep)
echo "Finding test methods in $CLASS_SIMPLE..."
TEST_METHODS=$(awk '
    /@Test/ {
        # Found @Test annotation, look for method in next few lines
        for (i=1; i<=5; i++) {
            if (getline > 0) {
                # Match method declaration: optional modifiers, return type, method name, parentheses
                if (match($0, /[[:space:]]+(void|[A-Za-z0-9_<>]+)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(/, arr)) {
                    # Extract just the method name
                    gsub(/^[[:space:]]+/, "", $0)
                    gsub(/[[:space:]]*\(.*/, "", $0)
                    # Find the last word (method name)
                    n = split($0, words, /[[:space:]]+/)
                    if (n >= 2) {
                        print words[n]
                        break
                    }
                }
            }
        }
    }
' "$FULL_PATH")

if [[ -z "$TEST_METHODS" ]]; then
    echo "No @Test methods found, running entire class..."
    TEST_TARGET="$CLASS_NAME"
else
    # Add "Run all tests in class" option
    SELECTED=$(echo -e "<< Run all tests in class >>\n$(echo "$TEST_METHODS" | sort)" | \
        fzf --prompt="Select test method: " --layout=reverse --exact -0 --height=33%)
    
    if [[ "$SELECTED" == "<< Run all tests in class >>" ]] || [[ -z "$SELECTED" ]]; then
        TEST_TARGET="$CLASS_NAME"
    else
        TEST_TARGET="$CLASS_NAME.$SELECTED"
    fi
fi

# Use GRADLE_MODULE if set, otherwise try to detect
if [[ ! -n "$GRADLE_MODULE" ]]; then
    # Detect the Gradle module (look for build.gradle)
    CURRENT_DIR=$(dirname "$FULL_PATH")
    while [[ "$CURRENT_DIR" != "/" ]]; do
        if [[ -f "$CURRENT_DIR/build.gradle" ]]; then
            MODULE_NAME=$(basename "$CURRENT_DIR")
            GRADLE_MODULE=":$MODULE_NAME:test"
            break
        fi
        CURRENT_DIR=$(dirname "$CURRENT_DIR")
    done
    
    # Fallback to :test if no module found
    GRADLE_MODULE="${GRADLE_MODULE:-:test}"
fi

# Build and run the gradle command
GRADLE_CMD="gradle $GRADLE_MODULE --tests $TEST_TARGET --rerun --info"

echo -e "\nRunning: $GRADLE_CMD\n"

eval "$GRADLE_CMD"

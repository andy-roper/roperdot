#
# Description: Runs a gradle test
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
gt: run a gradle test
Usage: gt [test-dir]

This script will look for a test with the directory specified by the
GRADLE_TEST_DIR env var (or the first parameter). It will recursively list
the classes in that path. Once you choose a class, you'll be prompted to
choose a test method.

After choosing a test method, gradle will be executed to run the method.
If the GRADLE_MODULE env var is used, that will be used as the module in the
command. Otherwise the script will derive the module name from build.gradle.
EOT
	exit 0
fi

set -e

# Priority: command-line arg > GRADLE_TEST_DIR env var > current directory
TEST_DIR="${1:-${GRADLE_TEST_DIR:-.}}"

# Expand ~ if present
TEST_DIR="${TEST_DIR/#\~/$HOME}"

if [[ ! -d "$TEST_DIR" ]]; then
    echo "Error: Directory not found: $TEST_DIR"
    exit 1
fi

# Find all test classes recursively, sort alphabetically, show relative paths
echo "Finding test classes under $TEST_DIR..."
TEST_FILE=$(find "$TEST_DIR" -type f \( -name "*Test.java" -o -name "*Tests.java" \) | \
    sort | \
    sed "s|^$TEST_DIR/||" | \
    fzf --prompt="Select test class: " --layout=reverse -0 --height 33%)

if [[ -z "$TEST_FILE" ]]; then
    echo "No test selected"
    exit 0
fi

# Reconstruct full path
FULL_PATH="$TEST_DIR/$TEST_FILE"

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
        fzf --prompt="Select test method: " --layout=reverse -0 --height=33%)
    
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
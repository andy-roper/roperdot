#
# Description: Kills Windows processes by PID or name pattern
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
killwin: kill Windows processes by PID or name pattern
Usage: killwin [-f] <PID|NAME_PATTERN>

Options:
-f  Force kill (taskkill /f)

Examples:
killwin 1234     Kill process with PID 1234
killwin chrome   Kill all processes containing 'chrome'
killwin -f edge  Force kill all edge processes
EOT
    exit 0
fi

FORCE=""
if [[ "$1" == "-f" ]]; then
    FORCE="/f"
    shift
fi

TARGET="$1"

# Check if target is a number (PID) or name pattern
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
    # Kill by PID
    taskkill.exe /pid "$TARGET" $FORCE
else
    # Kill by name pattern
    tasklist.exe /fo csv 2>/dev/null | awk -F',' -v pattern="$TARGET" -v force="$FORCE" '
    NR > 1 {
        gsub(/"/, "", $1)  # Image Name
        gsub(/"/, "", $2)  # PID
        if (tolower($1) ~ tolower(pattern)) {
            system("taskkill.exe /pid " $2 " " force)
        }
    }'
fi
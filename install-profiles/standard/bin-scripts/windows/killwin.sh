#
# Description: Kills Windows processes by PID or name pattern
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot

help() {
	cat <<EOT
killwin: kill Windows processes by PID or name pattern
Usage: killwin [-g] <PID1> [PID2] ... [PIDn]
       killwin [-g] <NAME_PATTERN>

Options:
-g  Graceful kill (no /f flag) - attempts graceful termination first

Examples:
killwin 1234 5678  Force kill processes with PIDs 1234 and 5678
killwin chrome     Force kill all processes containing 'chrome'
killwin -g 1234    Try graceful kill of PID 1234
EOT
	exit 0
}

[[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]] && help

PIDS_TO_KILL=()
PATTERN=
GRACEFUL=false

for arg in "$@"; do
    if [[ "$arg" == "-g" ]]; then
        GRACEFUL=true
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
       	[[ -n "$PATTERN" ]] && help
        PIDS_TO_KILL+=("$arg")
    else
        [[ -n "$PATTERN" || ${#PIDS_TO_KILL[@]} -gt 0 ]] && help
        PATTERN="$arg"
    fi
done

if [[ ${#PIDS_TO_KILL[@]} -eq 0 && -z "$PATTERN" ]]; then
	echo "killwin: not enough arguments"
	exit 1
fi

killpid () {
	local pid="$1"
    if [[ "$GRACEFUL" == true ]]; then
        result=$(taskkill.exe /pid "$pid" 2>&1)
        if [[ $? -eq 0 ]]; then
            :
        elif [[ "$result" == *"can only be terminated forcefully"* ]]; then
            echo "PID $pid can only be terminated forcefully"
        else
            echo "Failed to kill PID $pid: $result"
        fi
    else
        result=$(taskkill.exe /pid "$pid" /f 2>&1)
        [[ $? -ne 0 ]] && echo "Failed to kill PID $pid: $result"
    fi
    sleep 0.1
}

if [[ ${#PIDS_TO_KILL[@]} -gt 0 ]]; then
    for pid in "${PIDS_TO_KILL[@]}"; do
    	killpid $pid
    done
    exit 0
fi

PATTERN_PIDS=()
while IFS= read -r pid; do
    [[ -n "$pid" && "$pid" =~ ^[0-9]+$ ]] && PATTERN_PIDS+=("$pid")
done < <(tasklist.exe /fo csv 2>/dev/null | awk -F',' -v pattern="$PATTERN" '
NR > 1 {
    gsub(/"/, "", $1)  # Image Name  
    gsub(/"/, "", $2)  # PID
    if (tolower($1) ~ tolower(pattern)) {
        print $2
    }
}')

[[ ${#PATTERN_PIDS[@]} -eq 0 ]] && exit 1

for pid in "${PATTERN_PIDS[@]}"; do
	killpid $pid
done
#
# Description: Updates cron with jobs defined in ~/.config/roperdot/roperdot-cron-jobs.txt
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
update-cron: Update cron with jobs defined in ~/.config/roperdot/roperdot-cron-jobs.txt
Usage: update-cron

Define cron jobs in ~/.config/roperdot/roperdot-cron-jobs.txt using formats like these:

daily 20:30 ~/.config/roperdot/extra-bin/backup-reminder
weekdays 09:00 ~/.config/roperdot/extra-bin/sync-check
sunday 14:00 ~/.config/roperdot/extra-bin/weekly-task

Note: this script is only meant to manage calling scripts that reside within
the roperdot directory structure.
EOT
	exit 0
fi

ROPERDOT_CRON_FILE="$HOME/.config/roperdot/roperdot-cron-jobs.txt"
if [[ ! -f "$ROPERDOT_CRON_FILE" ]]; then
	echo "Error: ~/.config/roperdot/roperdot-cron-jobs.txt not found"
	exit 1
fi

TEMP_CRON=$(mktemp)

# Clean up temp file on exit
trap "rm -f '$TEMP_CRON'" EXIT

convert_to_cron() {
    local when="$1"
    local time="$2"
    local script="$3"
    
    # Parse time (HH:MM)
    local hour="${time%%:*}"
    local minute="${time##*:}"
    
    # Convert day specification to cron format
    case "$when" in
        sunday)    echo "$minute $hour * * 0 $script" ;;
        monday)    echo "$minute $hour * * 1 $script" ;;
        tuesday)   echo "$minute $hour * * 2 $script" ;;
        wednesday) echo "$minute $hour * * 3 $script" ;;
        thursday)  echo "$minute $hour * * 4 $script" ;;
        friday)    echo "$minute $hour * * 5 $script" ;;
        saturday)  echo "$minute $hour * * 6 $script" ;;
        weekdays)  echo "$minute $hour * * 1-5 $script" ;;
        weekends)  echo "$minute $hour * * 0,6 $script" ;;
        daily)     echo "$minute $hour * * * $script" ;;
        *)         
            echo "ERROR: Unknown schedule '$when' in line: $when $time $script" >&2
            exit 1
            ;;
    esac
}

# Export current crontab and remove roperdot-managed jobs
crontab -l 2>/dev/null | grep -v "roperdot" > "$TEMP_CRON"

# Add marker
echo "" >> "$TEMP_CRON"
echo "# Roperdot-managed jobs (auto-generated)" >> "$TEMP_CRON"

# Parse roperdot-cron-jobs.txt and convert
[[ -f "$ROPERDOT_CRON_FILE" ]] || echo "File not found"
while IFS= read -r line || [[ -n $line ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    
    read -r when time script <<< "$line"
    script="${script/#\~/$HOME}"
    if [[ ! -f "$script" ]]; then
    	echo "ERROR: Script not found in line: $line"
    	exit 1
    fi
    
    if [[ -n "$when" && -n "$time" && -n "$script" ]]; then
        convert_to_cron "$when" "$time" "$script" >> "$TEMP_CRON"
    fi
done < "$ROPERDOT_CRON_FILE"

# Install new crontab
crontab "$TEMP_CRON"

echo "Cron jobs updated"
echo ""
echo "Active roperdot jobs:"
crontab -l | grep "roperdot"
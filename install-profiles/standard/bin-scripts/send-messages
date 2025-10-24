#
# Description: (Windows) Sends lines from a text file to a Windows app
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
set -euo pipefail

APP_NAME="${1:-}"
MESSAGE_FILE="${2:-}"
DELAY_SECONDS="${3:-5}"

# Validate arguments
if [[ -z "$APP_NAME" || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" || -z "$MESSAGE_FILE" ]]; then
    cat <<EOT
send_messases: send lines from a text file to Windows app
Usage: send_messages <app_name> <message_file> <delay_seconds>

Arguments:
  app_name       Windows application name (process or window title)
  message_file   File containing messages (one per line)
  delay_seconds  Seconds to wait between messages (default: 5)

The script will:
  1. Send the first message immediately
  2. Wait delay_seconds before sending each subsequent message
  3. Send Enter after each message line
EOT
    exit 1
fi

if [[ ! -f "$MESSAGE_FILE" ]]; then
    echo "Error: Message file not found: $MESSAGE_FILE"
    exit 1
fi

if [[ ! "$DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid delay seconds value"
    exit 1
fi

# Read all messages into an array (normalize line endings and filter empty lines)
FILTERED_MESSAGES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove carriage returns to handle Windows line endings
    line="${line%$'\r'}"
    [[ -n "$line" ]] && FILTERED_MESSAGES+=("$line")
done < "$MESSAGE_FILE"

MESSAGE_COUNT=${#FILTERED_MESSAGES[@]}

if [[ $MESSAGE_COUNT -eq 0 ]]; then
    echo "Error: Message file is empty or contains only blank lines"
    exit 1
fi

# Escape single quotes in messages for PowerShell
escape_for_powershell() {
    local text="$1"
    # Replace single quotes with two single quotes for PowerShell string escaping
    echo "${text//\'/\'\'}"
}

# Send a single message to the application
send_message() {
    local message="$1"
    local escaped_msg=$(escape_for_powershell "$message")
    
    powershell.exe -NoProfile -Command "
        Add-Type -AssemblyName System.Windows.Forms
        
        \$processes = Get-Process | Where-Object { 
            \$_.MainWindowTitle -ne '' -and 
            (\$_.ProcessName -like '*$APP_NAME*' -or \$_.MainWindowTitle -like '*$APP_NAME*')
        }
        
        if (\$processes.Count -eq 0) {
            Write-Host 'No windows matching ''$APP_NAME'' found'
            exit 1
        }
        
        # Use the first matching process
        \$proc = \$processes[0]
        
        try {
            # Focus the window using Win32 API
            Add-Type @'
                using System;
                using System.Runtime.InteropServices;
                public class Win32 {
                    [DllImport(\"user32.dll\")]
                    public static extern bool SetForegroundWindow(IntPtr hWnd);
                }
'@
            [Win32]::SetForegroundWindow(\$proc.MainWindowHandle)
            Start-Sleep -Milliseconds 100
            
            # Send the message text followed by Enter
            [System.Windows.Forms.SendKeys]::SendWait('$escaped_msg')
            Start-Sleep -Milliseconds 50
            [System.Windows.Forms.SendKeys]::SendWait('~')
            
            exit 0
        } catch {
            Write-Host \"Failed to send message: \$_\"
            exit 1
        }
    " 2>&1
    
    return $?
}

echo "Verifying '$APP_NAME' is running..."
if ! send_message "" > /dev/null 2>&1; then
	echo "Error: Cannot find application $APP_NAME"
    exit 1
fi

cat <<EOT
=== send_messages ===
App:      $APP_NAME
File:     $MESSAGE_FILE
Messages: $MESSAGE_COUNT
Delay:    ${DELAY_SECONDS}s between messages

Starting in 2 seconds; press ctrl+C to cancel
EOT
sleep 2
echo ""

# Send messages
success_count=0
fail_count=0

for i in "${!FILTERED_MESSAGES[@]}"; do
    line_number=$((i + 1))
    message="${FILTERED_MESSAGES[$i]}"
    
    if [[ ${#message} -gt 60 ]]; then
        preview="${message:0:57}..."
    else
        preview="$message"
    fi
    
    echo "[$line_number/$MESSAGE_COUNT] Sending: $preview"
    
    if send_message "$message" > /dev/null 2>&1; then
        success_count=$((success_count + 1))
    else
        echo "Error: Failed to send the message"
        fail_count=$((fail_count + 1))
    fi
    
    # Wait before next message (except after the last one)
    [[ $line_number -lt $MESSAGE_COUNT ]] && sleep $DELAY_SECONDS
done

echo <<EOT

=== COMPLETED ===
Sent:   $success_count
Failed: $fail_count
Total:  $MESSAGE_COUNT
EOT

[[ $fail_count -gt 0 ]] && exit 1

exit 0
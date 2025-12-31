#
# Description: Sets a value in an INI file
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help() {
	cat <<EOT
set-ini-value: set a value in an INI file
Usage: set-ini-value <file_path> <section> <key> <value>

set-ini-value will set the referenced key to the specified value in an INI file
within the designated section.
EOT
	exit 0
}
[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

file_path="$1"
section="$2"
key="$3"
value="$4"

[[ -z "$file_path" || -z "$section" || -z "$key" || -z "$value" ]] && help

# Create directory if it doesn't exist
dir_path=$(dirname "$file_path")
[[ -d "$dir_path" ]] || mkdir -p "$dir_path"

# Create file if it doesn't exist
[[ -f "$file_path" ]] || touch "$file_path"

# Check if section exists
if grep -q "^\[${section}\]" "$file_path"; then
    # Section exists - check if key exists in that section
    if sed -n "/^\[${section}\]/,/^\[.*\]/p" "$file_path" | grep -q "^${key}="; then
        # Key exists - update it using sed
        sed -i.bak "/^\[${section}\]/,/^\[.*\]/ s/^${key}=.*/${key}=${value}/" "$file_path"
        rm -f "$file_path.bak"
    else
        # Key doesn't exist - add it after the section header using sed
        sed -i.bak "/^\[${section}\]/a\\
${key}=${value}" "$file_path"
        rm -f "$file_path.bak"
    fi
else
    # Section doesn't exist - add section and key at the end
    echo "" >> "$file_path"
    echo "[${section}]" >> "$file_path"
    echo "${key}=${value}" >> "$file_path"
fi

# echo "Updated ${file_path}: [${section}] ${key}=${value}"
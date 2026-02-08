#
# Description: Migrate roperdot to using ~/.config/roperdot
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
migrate-to-config: migrate roperdot to using ~/.config/roperdot
Usage: migrate-to-config <target-directory>

This script will move roperdot-generated files in the roperdot directory and in
your home directory to ~/.config/roperdot for better compartmentalization of
generated files.
EOT
    exit 0
fi

migration_dir="$1"
if [[ -n "$migration_dir" && ! -d "$migration_dir" ]]; then
	echo "Error: migration directory $migration_dir not found"
	exit 1
fi

if [[ -n "$migration_dir" ]]; then
	export ROPERDOT_DIR="$migration_dir"
	if [[ -f ~/roperdot/source-scripts/migrate-to-config ]]; then
		source ~/roperdot/source-scripts/migrate-to-config
	elif [[ -f ~/.config/roperdot/source-scripts/migrate-to-config ]]; then
		source ~/.config/roperdot/source-scripts/migrate-to-config
	else
		echo "Error: cannot find migrate-to-config source file"
	fi
else
	source "${ROPERDOT_DIR}"/source-scripts/migrate-to-config
fi

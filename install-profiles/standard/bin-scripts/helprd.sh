#
# Description: Shows help for roperdot aliases/binaries/functions and related applications
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ ! -e ~/roperdot-help.txt ]]; then
    echo Run ${ROPERDOT_DIR}/bin/generate-help before running help to build ~/roperdot-help.txt
    exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
    cat <<EOT
helprd: show help for roperdot aliases/binaries/functions and related applications
Usage: helprd [-g] [pattern]

Prints the contents of ~/roperdot-help.txt. If a pattern is provided, only those
lines that match will be shown.

To refresh the help file, run ${ROPERDOT_DIR}/bin/generate-help.

Switches
-g  Print general help
EOT
    exit 0
fi

if [[ $# -eq 0 ]]; then
    cat ~/roperdot-help.txt
elif [[ "$1" == "-g" ]]; then
	cat <<EOT
Fuzzy Finder (fzf) usage examples:
cd **<tab>
e subdir/**<tab>
kill -9 <tab>

To copy scripts from roperdot/bin-scripts to roperdot/bin-<shell>:
source roperdot/copy-scripts

To update the app binaries in roperdot/app-bin-<shell>:
update-app-binaries
EOT
else
    grep -i "$1" < ~/roperdot-help.txt
fi
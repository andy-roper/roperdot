#
# Description: Used by setnf to process output of set
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ -t 0 ]]; then
	cat <<EOT
process-setnf: used by setnf to process output of set
Usage: pipe data into process-setnf

process-setnf removes function definitions from the output of set.
EOT
	exit 0
fi

processing_funcs=
func_re=" \(\)$"
while read -r line; do
	if [[ -n "$processing_funcs" ]]; then
		[[ "$line" =~ $func_re ]] && echo "$line"
	else
		[[ ! "$line" =~ = ]] && processing_funcs=true
		echo "$line"
	fi	
done < /dev/stdin
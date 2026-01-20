#
# Description: Calls a REST API using curl
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
call-api: call a REST API using curl
Usage: call-api <operation> <url> [-d <data or data-file>] [--no-json-type] [header ...] 

Switches
-d <data>       Specify data to pass in the request body
                For GET operations, the data should be of the format "key=value".
                The value will be urlencoded by this script.
-d <data-file>  Specify a data file containing data to pass in the request body
--no-json-type  Don't include the "Content-Type: application/json" header

The header "Accept: application/json" will be automatically used.
The header "Content-Type: application/json" will be automatically included
unless the --no-json-type switch is used.

Data to be passed in the request body (or used as a URL query for a GET) can
also be piped into this command.

If the access_token environment variable is defined, it will be passed in a
bearer header token.

If the user_pass environment variable is defined, the username:password
value it contains will be passed in a basic authorization header.
EOT
	exit 0
}

[[ $# -lt 2 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help
operation=$1
args=("-sk" "-X" "$operation")
shift
[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help
url=$1
shift
data=
query=
headers=("Accept: application/json")
if [[ -z $SUPPRESS_PIPE ]] && ! test -t 0; then
	while read -r line || [[ -n "$line" ]]; do
		data+="$line"
	done < /dev/stdin
	if [[ -n "$data" ]]; then
		if [[ $operation = GET ]]; then
	   		p="${data%%=*}"
			v=$(urlencode "${data#*=}")
			query="$p=$v"
		else
			args+=("-d" "$data")
		fi
	fi
fi
while [[ $# -gt 0 ]]; do
	if [[ "$1" = -d ]]; then
		shift
		if [[ $operation = GET ]]; then
			# --data-urlencode only works for POST so I have to urlencode the value myself
			if [[ "$1" = *"&"* ]]; then
				query="$1"
			else
		   		p="${1%%=*}"
				v=$(urlencode "${1#*=}")
				[[ -n $query ]] && query="$query&$p=$v" || query="$p=$v"
			fi
		else
			args+=("-d")
			[[ -f "$1" ]] && args+=("@$1") || args+=("$1")
		fi
	elif [[ "$1" = "--no-json-type" ]]; then
		no_json_type=1
	else
		if [[ "$1" =~ : ]]; then
			headers+=("$1")
		else
			h="${1%% *}"
			v="${1#* }"
			headers+=("$h: $v")
		fi
	fi
	shift
done
[[ -z $no_json_type ]] && headers+=("Content-Type: application/json")
for h in "${headers[@]}"; do
	args+=("-H" "$h")
done
if [[ -n $access_token ]]; then
	args+=("-H" "Authorization: Bearer $access_token")
elif [[ -n $user_pass ]]; then
	args+=("--user" "$user_pass")
fi
[[ -n $query ]] && url="$url?$query"
args+=("$url")
# echo "args: ${args[@]}"
curl "${args[@]}"
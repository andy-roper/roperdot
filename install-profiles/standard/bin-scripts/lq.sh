#
# Description: Submits a query to a LoopBack application
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
lq: submit a query to a LoopBack application
Usage: lq <operation> <query> [data]

operation: GET, POST, PATCH or DELETE
query: Blahs, Blahs/123, Blahs/count, Blahs/my_behavior, etc.
data: 'key=value', value, JSON (for POST body), JSON file name

Sample calls:
lq POST Preferences/updatedPreferences payload.json
lq GET Cases/12345 'filter={"include":[{"relation":"agent","scope":null}]}'
lq GET Cases/12345 filter.json

The loopback_app_url environment variable will be used for the URL against
which to submit the REST API call. You should not include "/api" in the URL.

The accessToken environment variable will be used as the bearer token if it's
defined.

key=value data should be delimited in single quotes. Long strings of data
delimited by double quotes may be broken up unexpectedly resulting in portions
of the string being erroneously processed as headers.

For operations that accept query parameters, if the query doesn't contain an
equal then the key will be inferred from the query and operation if possible.

Query contains a slash:
Query ends with count: key = where
Query ends with /<digits>: data submission not supported

Query doesn't contain a slash:
POST operation: data provided will be submitted in the request body
GET operation: key = filter
PATCH or DELETE operation: key = where
EOT
	exit 0
}

# TO DO
# Is there any way to format JSON with jq to wrap keys in quotes?

# NOTES
# Can't assume "s" needs to be appended; e.g. AddressBookHistory

[[ $# -lt 2 || "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

[[ $ROPERDOT_CURRENT_SHELL = zsh ]] && operation=${1:u} || operation=${1^^}
if [[ ! " GET POST PATCH DELETE " =~ " $operation " ]]; then
	echo "Invalid operation; must be GET, POST, PATCH or DELETE"
	exit 1
fi

query=$2
data=$3
key=

args=($operation)
if [[ "$query" =~ http^ ]]; then
	args+=("$query")
else
	args+=("${loopback_app_url}/api/${query}")
fi
if [[ $query =~ / ]]; then
	if [[ $query =~ /count$ ]]; then
		key=where
	elif [[ $query =~ /[0-9]+$ ]]; then
		key=filter
	fi
else
	if [[ $operation = PATCH || $operation = DELETE ]]; then
		key=where
	elif [[ $operation = GET ]]; then
		key=filter
	fi
fi

# Process piped data and input files in call-api for POST operations
if [[ $operation != POST ]]; then
	if ! test -t 0; then
		export SUPPRESS_PIPE=true
		while read -r line || [[ -n "$line" ]]; do
			data+="$line"
		done < /dev/stdin
		data="$(echo "$data" | tr "\n" " " | tr "\t" " ")"
	elif [[ -f "$data" ]]; then
		data="$(cat "$data" | tr "\n" " " | tr "\t" " ")"
	fi
fi

if [[ -n "$data" ]]; then
	if [[ -n $key ]]; then
		if [[ "$data" =~ = ]]; then
			args+=("-d" "$data")
		else
			args+=("-d" "$key=$data")
		fi
	else
		args+=("-d" "$data")
#		if [[ "$data" =~ = || -f "$data" ]]; then
#			args+=("-d" "$data")
#		else
#			echo "Improperly formatted data: must provide 'key=value'"
#			exit 1
#		fi
	fi
fi
#echo "args: ${args[@]}"
call-api "${args[@]}"
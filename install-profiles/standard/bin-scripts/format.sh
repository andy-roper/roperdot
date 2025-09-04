#
# Description: Pretty-prints JSON, SQL, Javascript, HTML, XML or CSS and write the output to stdout; accepts file input, piped input or clipboard input
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
format: pretty-print JSON, SQL, Javascript, HTML, XML or CSS
Usage: format [-i|--in-place] [-t|--type <type>] [--writeclip] [filespec]

Options:
-i|--in-place     Update the input file with the formatted output
-t|--type <type>  Specify a formatting type: json, sql, js, html, css or xml
--writeclip       Write output to the clipboard (default is to write to stdout)

format will pretty-print JSON, SQL, Javascript, HTML, XML or CSS and write the
formatted string to stdout, or to the clipboard if the --writeclip option is
used. This script will read data from a file if it's supplied as an argument.
It will also accept piped input. If neither a file argument nor piped input are
provided, the script will read data from the clipboard.

Formatters used:
JSON        jq (https://stedolan.github.io/jq/)
SQL         Python 3 sqlparse module (https://github.com/andialbrecht/sqlparse)
Javascript  JS Beautifier (https://www.npmjs.com/package/js-beautify) or
            jsbeautifer (https://pypi.org/project/jsbeautifier/)
HTML        beautifulsoup4 (https://pypi.org/project/beautifulsoup4/)
XML         xmllint
CSS         cssbeautifier (https://pypi.org/project/cssbeautifier/)
EOT
#'
	exit 0
fi

detect_content_type () {
	local content="$1"
	local first_line=$(echo "${content%%$'\n*'}" | tr '[:upper:]' '[:lower:]')
	local json_re="^[[:blank:]]*[{[]"
	local xml_re="^'?<\?xml"
	local html_re="^[[:blank:]]*(<html|<!doctype html>)"
	if [[ "$first_line" =~ $json_re ]]; then
		echo json
	elif [[ "$first_line" =~ $xml_re ]]; then
		echo xml
	elif [[ "$first_line" =~ $html_re ]]; then
		echo html
	else
		local lc_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')
		local sql_re="^[[:blank:]]*(select|insert|update|delete|set|create|alter|drop)[[:blank:]]|\
[[:blank:]]*(select|insert|update|delete|set|create|alter|drop)[[:blank:]]"
		local css_re="^[^[:blank:]{]+[[:blank:]]*\{|\
[^[:blank:]{]+[[:blank:]]*{"
		if [[ "$lc_content" =~ $sql_re ]]; then
			echo sql
		elif [[ "$content" =~ $css_re ]]; then
			echo css
		else
			echo js
		fi
	fi
}

formatter_present () {
	case "$1" in
		json)
			command -v jq >/dev/null 2>&1 && return 0
			;;
		sql)
			command -v python3 >/dev/null 2>&1 && python3 -c "import sqlparse" >/dev/null 2>&1 && return 0
			;;
		html)
			command -v python3 >/dev/null 2>&1 && python3 -c "import bs4" >/dev/null 2>&1 && return 0
			;;
		css)
			command -v css-beautify >/dev/null 2>&1 && return 0
			;;
		xml)
			command -v xmllint >/dev/null 2>&1 && return 0
			;;
		js)
			command -v js-beautify >/dev/null 2>&1 && return 0
			;;
	esac
	return 1
}

format_file_content () {
	local temp_file
	if [[ -n "$in_place" ]]; then
		temp_file=$(mktemp)
		cp "$1" "$temp_file" >/dev/null
	fi
	case "$ext" in
		json)
			# For Windows, redirect the file contents instead of passing the filename as an argument
			# There's a known bug in jq; it crashes frequently on Windows when using relative paths
			if [[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]]; then
				if [[ -n "$temp_file" ]]; then
					# jq --tab "." < "$temp_file" > "$1"
					jq --indent 4 "." < "$temp_file" > "$1"
				else
					# jq --tab "." < "$1"
					jq --indent 4 "." < "$1"
				fi
			else
				if [[ -n "$temp_file" ]]; then
					# jq --tab "." "$temp_file" > "$1"
					jq --indent 4 "." "$temp_file" > "$1"
				else
					# jq --tab "." "$1"
					jq --indent 4 "." "$1"
				fi
			fi
			;;
		sql)
			if [[ -n "$temp_file" ]]; then
				parse-sql "$temp_file" > "$1"
			else
				parse-sql "$1"
			fi
			;;
		xml)
			# export XMLLINT_INDENT=$(echo -e "\t")
			export XMLLINT_INDENT="    "
			if [[ -n "$temp_file" ]]; then
				xmllint --format "$temp_file" > "$1"
			else
				xmllint --format "$1"
			fi
			;;
		js)
			if [[ "$js_command" = "js-beautify" ]]; then
				if [[ -n "$temp_file" ]]; then
					js-beautify --indent-with-tabs "$temp_file" > "$1"
				else
					js-beautify --indent-with-tabs "$1"
				fi
			else
				if [[ -n "$temp_file" ]]; then
					js-beautify "$temp_file" > "$1"
				else
					js-beautify "$1"
				fi
			fi
			;;
		html)
			if [[ -n "$temp_file" ]]; then
				beautify-html "$temp_file" > "$1"
			else
				beautify-html "$1"
			fi
			;;
		css)
			if [[ -n "$temp_file" ]]; then
				css-beautify "$temp_file" > "$1"
			else
				css-beautify "$1"
			fi
			;;
	esac
	[[ -n "$temp_file" ]] && rm -f "$temp_file" >/dev/null
}

format_content () {
	if [[ "$1" = "json" ]]; then
		echo "$str" | jq --tab "."
	elif [[ "$1" = "js" && "$js_command" = "js-beautify" ]]; then
		echo "$str" | js-beautify --indent-with-tabs
	else
		local temp_file=$(mktemp)
		if [[ "$1" = "xml" && "$str" =~ ^\' ]]; then  #'
			# Trim leading and trailing quote from xml if present (common in XML printed in logging)
			str="${str#\'}"
			str="${str%\'}"
		fi
		echo "$str" > "$temp_file"
		case "$1" in
			sql)  parse-sql "$temp_file" ;;
			xml)  export XMLLINT_INDENT=$(echo -e "\t")
				  xmllint --format "$temp_file"
				  ;;
			js)   beautify-js-pipe "$temp_file" ;;
			html) beautify-html "$temp_file" ;;
			css)  css-beautify "$temp_file" ;;
		esac
		rm -f "$temp_file" >/dev/null
	fi
}

while :; do
	if [[ "$1" = "--writeclip" ]]; then
		write_to_clipboard=true
		shift
	elif [[ "$1" = "-t" || "$1" = "--type" ]]; then
		shift
		data_type=$1
		shift
	elif [[ "$1" = "-i" || "$1" = "--in-place" ]]; then
		in_place=true
		shift
	else
		break
	fi
done

check_for_input_file=true
get_input_add_spaces=true
. "${ROPERDOT_DIR}/source-scripts/get-input"

if [[ -n "$input_file" ]]; then
	ext=$(echo "${input_file##*.}" | tr '[:upper:]' '[:lower:]')
	if [[ -n "$write_to_clipboard" && -t 1 ]]; then
		format_file_content "$1" | clipcopy
	else
		if formatter_present "$ext"; then
			format_file_content "$1"
		else
			echo Formatter not found for file type "$ext"
			exit 1
		fi
	fi
else
	if [[ -n "$in_place" ]]; then
		echo "No input file provided"
		exit 1
	fi
	if [[ -n "$str" ]]; then
		if [[ "$str" =~ ^\" ]]; then
            str=${str#\"}
            str=${str%\"}
            str=$(echo $str | sed 's/\\"\\"/""/g' | sed 's/\([^\\]\)\\"/\1"/g' | sed 's/\\\\\\"/\\"/g' | sed 's/\\\\"/\\"/g')
		elif [[ "$str" =~ ^\$\' || "$str" =~ \'$ ]]; then
			str=${str#\$\'}
			str=${str%\'}
		fi
		[[ -z "$data_type" ]] && data_type=$(detect_content_type "$str")

		if ! formatter_present $data_type; then
			echo Formatter not found for data type "$data_type"
			exit 1
		fi

		if [[ -n "$write_to_clipboard" && -t 1 ]]; then
			format_content "$data_type" | clipcopy
		else
			format_content "$data_type"
		fi
	else
		echo "No data provided to format"
	fi
fi
#
# Description: Prints a table of ASCII characters
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
ascii: print a table of ASCII characters
Usage: ascii
EOT
#'
	exit 0
fi

# 111 0x1A SUB   111 0x1A SUB
# Each column is 12 characters with 3 spaces right padding
# width = n * 12 + (n - 1) * 3 = 12n + 3n - 3 = 15n - 3

cols=$(( (COLUMNS + 2) / 15 ))
if [[ $(( (ROWS - ROPERDOT_PROMPT_LINES) * cols )) -lt 256 ]]; then
	rows=$(( 256 / cols ))
	[[ $(( cols * rows )) -lt 256 ]] && (( ++rows ))
else
	rows=$(( ROWS - ROPERDOT_PROMPT_LINES ))
fi

set -f
ext_ascii="ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ "

asc () {
	local char
	if [[ $1 -gt 127 ]]; then
		local index=$(($1 - 128))
		char=${ext_ascii:$index:1}
	else
		case $1 in
			0)   char="NUL" ;;
			1)   char="SOH" ;;
			2)   char="STX" ;;
			3)   char="ETX" ;;
			4)   char="EOT" ;;
			5)   char="ENQ" ;;
			6)   char="ACK" ;;
			7)   char="BEL" ;;
			8)   char="BS" ;;
			9)   char="HT" ;;
			10)  char="LF" ;;
			11)  char="VT" ;;
			12)  char="FF" ;;
			13)  char="CR" ;;
			14)  char="SO" ;;
			15)  char="SI" ;;
			16)  char="DLE" ;;
			17)  char="DC1" ;;
			18)  char="DC2" ;;
			19)  char="DC3" ;;
			20)  char="DC4" ;;
			21)  char="NAK" ;;
			22)  char="SYN" ;;
			23)  char="ETB" ;;
			24)  char="CAN" ;;
			25)  char="EM" ;;
			26)  char="SUB" ;;
			27)  char="ESC" ;;
			28)  char="FS" ;;
			29)  char="GS" ;;
			30)  char="RS" ;;
			31)  char="US" ;;
			32)  char="SPC" ;;
			127) char="DEL" ;;
			*)   char=$(printf "\\x${hex}") ;;
		esac
	fi
	echo "$char"
}

row=1
while [[ $row -le $rows ]]; do
	unset str
	code=$(( row - 1 ))
	while (( code < 256 )); do
		hex=$(printf "%02X" $code)
		char=$(asc $code)
		[[ -n "$str" ]] && str="$str  "
		x="$(printf "%3s 0x%s %s" $code "$hex" "$char")"          
		y="$(printf "%-13s" "$x")"
		
		# Had to add this kludge because sometimes the above printf results in less than 13 characters
		padding=$(( 13 - ${#y} ))
		while [[ $padding -gt 0 ]]; do
			y="$y "
			(( ++padding ))
		done
		
		str="$str$y"
		(( code += rows ))
	done

	echo "$str"

	(( ++row ))
done
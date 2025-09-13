#
# Description: Examples of various approaches in bash and zsh
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
# Exit without doing anything if executed
echo "This script is not meant to be executed; it's a set of bash and zsh scripting examples."
exit 0

# Use a default value in an expression with "-"
export color_scheme=${color_scheme:-hybrid}  # export value of color_scheme, or "hybrid" if it's not defined
f=${1:-$VALUE}  # set f to $1, or to $VALUE if $1 isn't defined

# Execute a block of code if a condition is true or false
[[ "$var" = alpha ]] && {
	echo $var equals alpha;
}
[[ "$var" = alpha ]] || {
	echo $var does not equal alpha;
}

# Get the length of a string variable value
str=123456
echo ${#str}     # 6

# Get a substring of a string variable value
str=abcABC123ABCabc
echo ${str:1}    # bcABC123ABCabc
echo ${str:7:3}  # 23A
echo ${str: -4}  # Cabc (last 4 characters of the string)

# Remove substring from the start of a string variable value
str=abcABC123ABCabc
echo ${str#a*C}   # 123ABCabc
echo ${str##a*C}  # abc

# Remove substring from the end of a string variable value
str=abcABC123ABCabc
echo ${str%b*c}   # abcABC123a
echo ${str%%b*c}  # a

# Replace first occurrence of pattern in a string
str="I can see for miles and miles and miles"
str2="${str/miles/kilometers}"  # "I can see for kilometers and miles and miles"

# Replace all occurrences of pattern in a string
str="I can see for miles and miles and miles"
str2="${str//miles/kilometers}"  # "I can see for kilometers and kilometers and kilometers"

# Convert a string to uppercase
ucvalue=${var^^}  # bash
ucvalue=${var:u}  # zsh

# Convert a string to lowercase
lcvalue=${var,,}  # bash
lcvalue=${var:l}  # zsh

# Compare with regex in condition and capture values
re="^([A-Z]+)[^0-9]+([0-9]+)$"
str="ABCxyz123"
# bash
[[ "$str" =~ $re ]] && echo ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}  # ABC 123
# zsh
[[ "$str" =~ $re ]] && echo $match[1] $match[2]  # ABC 123

# Increment a value
i=5
(( i++ ))
echo $i  # 6

# Add a value to variable
i=10
(( i += 5 ))
echo $i  # 15

# Define an array
my_array=()                        # Define the array
define -a my_array                 # Another way to define an array
my_array=("alpha" "beta" "gamma")  # Defining and initializing an array
my_array=("${another_array[@]}")   # Cloning an array

# Get the length of an array
len=${#my_array[@]}

# Append values to array
my_array+=("delta" "epsilon")

# Concatenate arrays
array_one+=("${array_two[@]}")

# Execute a command and pass an array of arguments
some_command "${my_array[@]}"

# Slice an array
my_array=("alpha" "beta" "gamma" "delta" "epsilon")
# bash
echo "${my_array[@]:3}"    # delta epsilon
echo "${my_array[@]:1:2}"  # beta gamma
# zsh
echo "${my_array:3}"       # delta epsilon
echo "${my_array:1:2}"     # beta gamma

# Get the last element of an array
echo "${my_array[@]: -1}"  # bash
echo "${my_array: -1}"     # zsh

# Remove the last element of an array
unset 'my_array[${#my_array[@]} - 1]'  # bash
my_array[${#my_array[@]}]=()           # zsh

# Split a string into an array using a single-character delimiter
str="alpha,beta,gamma,delta"
# bash
IFS=',' read -ra my_array <<< "$str" # my_array = ("alpha" "beta" "gamma" "delta")
# zsh
my_array=("${(@s/,/)str}")           # my_array = ("alpha" "beta" "gamma" "delta")

# Split a tab-delimited string into an array
str="alpha\tbeta\tgamma\tdelta"
# bash
IFS=$'\t' read -ra my_array <<< "$str" # my_array = ("alpha" "beta" "gamma" "delta")
# zsh
my_array=("${(@s/\t/)str}")            # my_array = ("alpha" "beta" "gamma" "delta")

# Split a string into an array using a multi-character delimiter
str="alpha::beta::gamma::delta"
# bash
delimiter="::"
str+=$delimiter
my_array=()
while [[ $str ]]; do
	my_array+=( "${str%%"$delimiter"*}" )
	str=${str#*"$delimiter"}
done                         # my_array = ("alpha" "beta" "gamma" "delta")
# zsh
my_array=("${(@s/::/)str}")  # my_array = ("alpha" "beta" "gamma" "delta")

# Check if an array contains/includes a value
[[ " ${my_array[@]} " =~ " ${value} " ]] && echo yep  # Only valid if none of the values contain spaces

# Check if an array contains a variable value (spaces are honored)
v="alpha"
pattern="^${v}$" && printf '%s\n' "${my_array[@]}" | grep -qP $pattern && echo yep 

# Associative arrays
declare -A my_hash
my_hash[key]="value"
echo ${my_hash[key]}

# Get all keys in an associative array
echo ${!my_hash[@]}  # bash
echo ${(k)my_hash}   # zsh

# Get all values in an associative array
echo ${my_hash[@]}

# Check if key exists in associative array
[[ -n ${my_hash[key]+x} ]] && echo yep

# Read a file into an array (Bash 4 or later)
readarray -t my_array < my-file.txt

# Read a file into an array (zsh)
zmodload zsh/mapfile
my_array=("${(f)mapfile[someFile.txt]}")

# Output the results of a command into an array (Bash 4 or later)
readarray -t my_array < <(my_command)

# Output the results of a command into an array (zsh)
my_array=("${(@f)$(my_command)}")

# Loop over arguments by omitting "in" from for
print_args() { local v; for v; do echo "$v"; done; }
print_args "alpha" "beta" "gamma"  # echoes "alpha\nbeta\ngamma\n"

# Loop over the elements of an array
array=("alpha" "beta" "gamma")
for v in "${array[@]}"; do echo "$v"; done  # echoes "alpha\nbeta\ngamma\n"

# Counted loop
for ((i = 0; i < 10; i++)); do echo "in loop"; done

# Endless loop
count=0
while : ; do
	(( ++count ))
	[[ $count -gt 5 ]] && break
done

# Check if a command is defined
command -v some_command >/dev/null 2>&1 && echo yep

# Use the binary for a command instead of a function or alias with the same name
\some_command
command some_command
builtin some_command

# Perform an operation on each result from a command
while IFS= read -r -d '' src_file; do
	echo $src_file
done < <(find . -type f -print0)

# Perform an operation on each line of a file
while IFS= read -r line; do
	echo $line
done < someFile.txt

# Print a heredoc
cat <<EOT
Some text
Some more text
EOT

# Print a heredoc to a file
cat << EOT > some-file.txt
First line
Second line
EOT

# Read a heredoc into a variable
read -r -d '' file_var << EOT
Line 1
Line 2
EOT

# Here strings (alternative to echo | command)
grep "pattern" <<< "$variable"
wc -w <<< "count these words"

# Process substitution for commands that need files
diff <(sort file1) <(sort file2)
while read -r line; do echo "Line: $line"; done < <(find . -name "*.txt")

# Command substitution with error handling
if output=$(command 2>&1); then
    echo "Success: $output"
else
    echo "Failed: $output"
fi

# Process command line options with getopts
OPTIND=1
while getopts "hvf:" opt; do
    case $opt in
        h) show_help; exit 0 ;;
        v) verbose=true ;;
        f) filename="$OPTARG" ;;
        *) show_help; exit 1 ;;
    esac
done
shift $((OPTIND-1))  # Remove processed options from $@

# Read a typed value from the user
read answer_var

# Read a keystroke from the user; the response will be in the REPLY env var
read -p "Accept [y/N]? " # bash
read "?Accept [y/N]? "   # zsh

# Prompt the user to select an option from an array
PS3="Select an option: "
while [[ -z "$scheme" ]]; do
	select scheme in "${schemes[@]}"; do
		break
	done
done
# The selected value from the array (not the index) will be stored in the variable
# The REPLY environment variable will contain the number the user entered

# Prompt the user to select an option from a static list
PS3="Select an option: "
while [[ -z "$scheme" ]]; do
	select scheme in "option one" "option two" "option three"; do
		break
	done
done

# Prompt the user to select an option from an array and only print one choice per line
PS3="Select an option: "
COLUMNS_OLD=$COLUMNS
COLUMNS=12  # limit the number of columns in which to display the option
while [[ -z "$scheme" ]]; do
	select scheme in "${schemes[@]}"; do
		break
	done
done
COLUMNS=$COLUMNS_OLD

# Prompt the user to select an option from a file's contents using fzf
echo "Select a file"
f="$(cat some-file.txt | sort | fzf --no-sort -0 --height 33% --layout=reverse)"

# Prompt the user to select an option from a list generated by a command using fzf
echo "Select a file"
f="$(find . -maxdepth 1 -type f -printf '%f\n' | sort | fzf --no-sort -0 --height 33% --layout=reverse)"

# Case statement with patterns
case "$filename" in
    *.txt|*.md)     echo "Text file" ;;
    *.jpg|*.png)    echo "Image file" ;;
    [Mm]akefile)    echo "Makefile" ;;
    *)              echo "Unknown type" ;;
esac

# Echo directly to the terminal (often used in a function that echoes an output value)
echo "text" >/dev/tty

# Pipe usage
if ! test -t 0; then  # have piped data
    while read -r line || [[ -n "$line" ]]; do
    	echo $line
    done < /dev/stdin
fi

# Check if running in terminal vs script
if test -t 1; then
    echo "Running in terminal (stdout is a tty)"
else
    echo "Output is being redirected or piped"
fi

# Get the directory of the current script
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Get the name of the current script without path
script_name="${0##*/}"

# Get process ID of background job
some_command &
bg_pid=$!

# Wait for background process with timeout
timeout 10 wait $bg_pid

# Check if a command exists and get its type
command -v git >/dev/null 2>&1 && echo "git exists"
command_type="$(type -t git)"           # bash: returns "builtin", "alias", "function", "file", etc.
command_type=${"$(whence -w git)"#*: }  # zsh: returns "command", "alias", "function", etc.

# Get terminal width
terminal_width=$(tput cols)
# or
terminal_width=${COLUMNS:-80}

# Colors and formatting (using tput)
red=$(tput setaf 1)
green=$(tput setaf 2)
bold=$(tput bold)
reset=$(tput sgr0)
echo "${red}Error:${reset} ${bold}Something went wrong${reset}"

# trap usage
trap "rm -f $temp_file >/dev/null" EXIT  # execute command on script exit
trap my_function SIGINT  # execute command on Ctrl-C
trap "" SIGINT  # disable trapping of Ctrl-C
trap - SIGINT   # resume trapping of Ctrl-C

# User-defined traps
# In script:
trap my_function USR1
# Command line
$ kill -SIGUSR1 1001

# Do multi-line replacement in a file
# Undefining $/ is the key
perl -p -i -e 'BEGIN{undef $/;} s/("installed_packages":[^\]]*),(\s*\])/\1\2/s' my-file.json

# Find recently modified files
find . -type f -mtime -7  # Last 7 days
find . -type f -mmin -60  # Last 60 minutes
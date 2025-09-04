#
# Description: Compiles a Java class
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
jc: compile a Java program
Usage: jc <Java file>

This script will compile a Java source file. The .java extension in the file
name is optional; if the filename provided doesn't end with .java, the script
will look for a file with that name ending with .java.
EOT
	exit 0
fi

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

switches=
while [[ "$1" =~ ^- ]]; do
	switches="$switches $1"
	shift
done

if [[ "$1" =~ \.java$ ]]; then
	file_path=${1%%\.java}
	source=$1
else
	file_path=$1
	source=$1.java
fi
if [[ ! -f "${file_path}.class" || "$1" -nt "${file_path}.class" ]]; then
	temp_file=$(mktemp)
	[ -z "$JAVA_HOME" ] && CLASSPATH=$(build-classpath) || CLASSPATH=$(build-classpath "$JAVA_HOME/jre/lib" "$JAVA_HOME/lib")
	CLASSPATH="$CLASSPATH" javac "$switches" "$source" > "$temp_file" 2>&1
	if [[ $ROPERDOT_OS_ENV = darwin && $current_shell = bash && $ROPERDOT_SHELL_VERSION = 3 ]]; then
		filesize=$(stat -f%z "$temp_file")
	else
		filesize=$(stat --printf="%s" "$temp_file")
	fi
	[[ "$filesize" -eq 0 ]] && echo "Successful compile of $1." || cat "$temp_file"
	rm "$temp_file"
else
	echo Class file for $1 is up to date.
fi
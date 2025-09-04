#
# Description: Runs a Java class or JAR
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
jr: Execute a Java class or jar file
Usage: jr <Java class or jar>
EOT
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

if [[ $# -eq 0 ]]; then
	java
	exit 0
fi

target="$1"
shift
[ -z "$JAVA_HOME" ] && CLASSPATH=$(build-classpath) || CLASSPATH=$(build-classpath "$JAVA_HOME/jre/lib" "$JAVA_HOME/lib")
if [[ "$target" =~ \.class$ ]]; then
	ext=class
elif [[ "$target" =~ \.jar$ ]]; then
	ext=jar
else
	if [[ -f "$target.class" ]]; then
		ext=class
	elif [[ -f "$target.jar" ]]; then
		ext=jar
	fi
fi
if [[ "$ext" = class ]]; then
	if [[ "$target" =~ / ]]; then
		path=${target%/*}
		[[ "$ROPERDOT_DESKTOP_ENV" = windows ]] && CLASSPATH="$path;$CLASSPATH" || CLASSPATH="$path:$CLASSPATH"
	fi
	target=${target##*/}
	target=${target%.class}
	CLASSPATH="$CLASSPATH" java "$target" "$@"
else
	CLASSPATH="$CLASSPATH" java -jar "$target" "$@"
fi
#
# Description: Prints a classpath value containing the JAR files in the current directory and optional arbitrary directories
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
build-classpath: print a classpath value containing the JAR files in the current
directory and optional arbitrary directories
Usage: build-classpath [directory ...]
EOT
	exit 0
fi
classpath=.
[[ "$ROPERDOT_DESKTOP_ENV" = "windows" ]] && sep=";" || sep=:
for d; do
	if [[ -d "$d" ]]; then
		while IFS= read -r -d '' jar; do
			classpath="$classpath$sep$jar"
		done < <(find "$d" -maxdepth 1 -name "*.jar" -print0)
	fi
done
echo "$classpath"
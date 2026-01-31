#
# Description: Runs IntelliJ IDEA
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
idea: run IntelliJ IDEA
Usage: idea <parameters>
EOT
	exit 0
}

flatpak run com.intellij.idea.ultimate "$@"
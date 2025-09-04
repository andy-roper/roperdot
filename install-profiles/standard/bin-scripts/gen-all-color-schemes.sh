#
# Description: Calls gen-color-files for each available color scheme
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
gen-all-color-schemes: call gen-color-files for each color scheme
Usage: gen-all-color-schemes

gen-all-color-schemes will call gen-color-files for each color scheme that's
packaged with roperdot.
EOT
	exit 0
fi

gen-color-files chalkboard
gen-color-files flat
gen-color-files gruvbox light
gen-color-files hybrid
gen-color-files jellybeans
gen-color-files monokai
gen-color-files peppermint
gen-color-files pnevma
gen-color-files smyck
gen-color-files "solarized dark alternate"
gen-color-files "solarized dark higher contrast"
gen-color-files "solarized light alternate" light
gen-color-files "spacegray eighties"
gen-color-files "spacegray eighties dull"
gen-color-files srcery
# \cd "${ROPERDOT_DIR}/config/color-schemes/source"
# rm -rf default
# mkdir default
# cp -r hybrid/* default
#
# Description: Moves all files in subdirectories up into the current directory
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
help () {
	cat <<EOT
flatten: move files in subdirectories of a directory into the directory
Usage: flatten [target_dir]

flatten will move all files in subdirectories of a directory up into that
directory. If no directory parameter is provided, the current directory
will be used.
EOT
	#'
	exit 0
}

[[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]] && help

[[ -z $current_shell ]] && export current_shell=$(ps h -p $$ -o args='' | cut -f1 -d' ')

files=()
d=$1
if [[ -z "$d" ]]; then
	d=.
else
	[[ ! -d "$d" ]] && help
fi
while IFS= read -r -d '' src_file; do
	dst_file="${src_file##*/}"
	[[ ! -e "$d/$dst_file" ]] && files+=("$src_file")
done < <(find "$d" -type f -print0)

file_count=${#files[*]}
if [[ $file_count -eq 0 ]]; then
	echo Nothing to do.
else
	if [[ "$d" == "." ]]; then
		dir_name="the current directory"
	else
		dir_name="$d"
	fi
	if [[ $current_shell = bash ]]; then
		read -p "This will move $file_count files to $dir_name. Warning: any duplicate filenames between the subdirectories and the target directory will be overwritten. Continue (y/N)? " -n 1
	else
		read -k 1 "?This will move $file_count files to $dir_name. Warning: any duplicate filenames between the subdirectories and the target directory will be overwritten. Continue (y/N)? "
	fi
	if [[ $REPLY =~ ^[yY]$ ]]; then
		for src_file in "${files[@]}"; do
			mv "$src_file" "$d"
		done
	fi
fi
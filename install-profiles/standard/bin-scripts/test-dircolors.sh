#
# Description: Creates sample files for testing .dircolors
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -gt 0 ]]; then
	cat <<EOT
test-dircolors: create sample files for testing .dircolors
Usage: test_dircolors

This script will create the directory ~/test-dircolors and create sample files
in it based on the file names and extensions referenced in
~/roperdot/dircolors_source.txt. You can use these sample files to test your
.dircolors color scheme.

Categories are specified in dircolors_source.txt like:

category: some-category

A subdirectory will be created for each category in dircolors_source.txt.
Sample files for the filenames in that section (until the value of category is
changed) will be created in that subdirectory, in addition to being created in
~/test-dircolors/all-files.

If the filename specified in dir_colors_source.txt begins with an asterisk and
it's not in the "special" category, a sample file will be created using the
pattern as an extension, e.g. "*zip" => "test file.zip".
EOT
#'
	exit 0
fi

. "${ROPERDOT_DIR}/source-scripts/re-match"

process_line () {
	if [[ "$line" =~ $space_re ]] || [[ "$line" =~ $skip_re ]]; then
		return
	fi
#	if [[ "$line" =~ $category_re ]]; then
#		category=${BASH_REMATCH[1]}
	if re_match "$line" $category_re; then
		category=${re_match[1]}
		if [[ -n "$category" ]]; then
			mkdir ~/test-dircolors/"$category"
			cd ~/test-dircolors/"$category" || exit 1
		fi
#	elif [[ "$line" =~ $file_re ]]; then
#		pattern=${BASH_REMATCH[1]}
	elif re_match "$line" $file_re; then
		pattern=${re_match[1]}
		if [[ "$category" = "special" ]]; then
			filename=${pattern/\*}
		elif [[ "$pattern" =~ ^\\* ]]; then
			filename="test file${pattern/\*/.}"
		else
			filename=${pattern/\*}
		fi
		touch "./$filename"
		touch "../all-files/$filename"
	fi
}

create_attribute_test_files () {
	touch multi_link
	ln multi_link hard_link
	ln -s multi_link soft_link
	touch executable
	chmod u+x executable
	mkfifo fifo

	# socket file: not sure how to create
	# https://www.linuxquestions.org/questions/linux-software-2/how-can-i-create-a-socket-file-248399/#post4398605
	# door file: not sure how to create

	if [[ "$ROPERDOT_OS_ENV" != "darwin" ]]; then
		# Create block special file
		mknod blk b 100 1 > /dev/null 2>&1
		# Create character special file
		mknod chr c 100 1 > /dev/null 2>&1
	fi
	
	# Create an orphaned link
	touch linked_file
	ln -s linked_file orphaned_link
	rm linked_file
}

[[ -d ~/test-dircolors ]] && rm -rf ~/test-dircolors
mkdir ~/test-dircolors
cd ~/test-dircolors || exit 1
mkdir all-files
mkdir attributes
cd all-files || exit 1

create_attribute_test_files

# Repeat process in attributes directory
cd ../attributes || exit 1
create_attribute_test_files
cd ..

IFS=$'\n'
skip_re="^[[:space:]]*(#|color:|COLOR|OPTIONS|TERM|EIGHTBIT|NORM|FILE|DIR|SYMLINK|LINK|LNK|MULTIHARDLINK|EXEC|PIPE|FIFO|SOCK|DOOR|BLOCK|BLK|CHAR|CHR|ORPHAN|MISSING|RESET|SETUID|SETGID|CAPABILITY|STICKY|OTHER_WRITABLE|LEFT|RIGHT|END)"
space_re="^[[:space:]]*$"
category_re="^[[:space:]]*category:[[:space:]]*([^ ]+)?"
file_re="^[[:space:]]*([[:graph:]]+)"
IFS=
while read -r line; do
	process_line
done < "${ROPERDOT_DIR}/dircolors_source.txt"
process_line

mkdir ~/test-dircolors/_one_each
cd ~/test-dircolors/_one_each || exit 1
create_attribute_test_files
touch ".bashrc" "test file.txt" "test file.zip" "test file.chd" "test file.html" "test file.jpg" "test file.pdf" "test file.sh"

echo Done populating ~/test-dircolors
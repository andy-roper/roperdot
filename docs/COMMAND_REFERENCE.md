# Command Reference

This reference enumerates the functions, aliases, and enhanced commands included in roperdot.

## Quick Reference

Use the built-in help system for any command:
```bash
help <command>     # Get help for a command
help <text>        # Find commands whose name/description matches the text
<command> --help   # Individual command help
```

## Application Integration

- **`e`** - Opens files in an appropriate GUI editor based on the file extension:
  - Archives are opened in archive apps
  - Images in image viewers
  - Videos in video players
  - PDFs in PDF readers
  - Documents in productivity applications
  - Web files in browsers
  - Text files in text editors (or VS Code if in a terminal in that context)
- **`v`** - Opens files in an appropriate viewer based on the file extension:
  - Archives' contents are listed in the shell
  - Images in image viewers
  - Videos in video players
  - PDFs in PDF readers
  - Documents in productivity applications
  - Web files in browsers
  - Text files in `less`
- **`fm`** - Open GUI file manager in current directory or a target directory

## File Management and Navigation

### Navigation
- **`cd` (enhanced)** - Smart directory navigation with [fzf](https://github.com/junegunn/fzf) fuzzy finding and archive extraction; also handles `cd ...` etc.
- **`cdclip`** - cd to the directory contained in the clipboard
- **`cdd`** - Fuzzy select and navigate to subdirectory using [fzf](https://github.com/junegunn/fzf)
- **`cdf` (Mac)** - cd into the folder being viewed in the forefront Finder window
- **`cdp`** - cd to the previous directory
- **`cds`** - Deep subdirectory selection with recursive search
- **`mdd`** - Create a directory and cd into it
- **`t`** - create a temporary directory within the current directory and cd to it
- **`up`** - Select and navigate to parent directory levels
- **`-`** - cd to the previous directory
- **`~`** - cd to your home directory
- **`.`** - (with no arguments) cd to your home directory
- **`..`** - `cd ..`
- **`...`** - `cd ../..`
- **`....`** - `cd ../../..`
- **`.....`** - `cd ../../../..`

### Listing
- **`ls` (enhanced)** - Enhanced formatting, colors, and sorting options
- **`l`** - Same as standard `ls -al`
- **`la`** - ls showing permissions in octal
- **`lb`** - ls with one filename per line
- **`lf`** - ls that shows full paths to files, one filename per line
- **`lfr`** - Recursive lf
- **`lh`** - Similar to `ls -alh`, but shows 5 digits of precision for sizes
- **`lsd`** - ls that only shows directories
- **`lsz`** - ls sorted by size ascending
- **`lt`** - ls sorted by modified time ascending
- **`lw`** - Same as standard ls
- **`recent`** - List recently modified files
- **`u`** - Show space used by subdirectories in human-readable formatting

### File Manipulation
- **`cp` (enhanced)** - Copy with safety features and progress indication
- **`cpp`** - Copy files and show progress using `rsync`
- **`cpr`** - Recursive copy
- **`flatten`** - Move files from subdirectories up to current directory
- **`md` (enhanced)**  - Create a directory and create parent directories as needed (`mkdir -p`)
- **`mdd`** - Create a directory and cd into it
- **`mv` (enhanced)** - Move with confirmation prompts for destructive operations
- **`rd`** - Remove a directory (same as `rmdir`)
- **`ren`** - Regex-based file renaming with pattern matching
- **`rm` (enhanced)** - File removal defaults to interactive unless overridden with an option
- **`rt`** - Recursive text replacement in files
- **`rtr`** - Recursive text replacement with regex patterns

### File Utilities
- **`abs-path`** - Echo the absolute path for a path including resolving "..." as "../.." in the path
- **`chmox`** - `chmod u+x`
- **`fs`** - Display file status for a file using stat
- **`modtime`** - Print the modified time for a file in a format that's compatible with touch
- **`rmdsstore` (Mac)** - Remove *.DS_Store under the current directory
- **`vb`** - View a file in binary/hex mode
- **`vt`** - View a file in text mode

### Searching
- **`apt-file`** - Indexes available package contents to allow you to search for a file among them
- **`ff`** - Recursively find files by name
- **`fsz`** - Find files by name and print size information
- **`ft`** - Find files by content using [The Silver Searcher](https://github.com/ggreer/the_silver_searcher) or grep
- **`ftr`** - Recursively find files by content using [The Silver Searcher](https://github.com/ggreer/the_silver_searcher) or grep

### Comparing and Synchronizing
- **`bindiff`** - Compare files in binary/hex mode
- **`dc`** - Directory compare
- **`dirdiff`** - Show differences between directories
- **`hexdiff`** - Compare files in binary/hex mode
- **`jsondiff`** - Compare JSON files
- **`syncdir`** - Sync the files in a source directory with a target directory

### Archive Operations
- **`c`** - Compress files/directories with automatic format detection based on target extension
  - `c archive.tar.gz folder/` - Creates tar.gz
  - `c backup.zip files/` - Creates zip file
  - `c archive source/` - Creates archive whose extension is based on the `ROPERDOT_ARC_TYPE` env var
  - Supports: zip, tar.gz, tar.bz2, tar.xz, 7z
- **`cr`** - Compress files recursively
- **`x`** - Extract archive into the current directory with automatic format detection
- **`xd`** - Extract archive into subdirectory with same base filename
- **`xdd`** - Extract all archives in current directory into subdirectories

## Development and Text Processing

### Text/Data Formatting
- **`clip2bullets`** - Converts a bulleted presentation slide image in the clipboard to text
- **`d2u`** - Uses dos2unix to change linefeeds for Unix compatibility
- **`format`** - Beautify and format various file types: JSON, SQL, JavaScript, HTML, CSS and XML
- **`format-clip`** - Pretty-print JSON, SQL, Javascript, HTML, XML or CSS and write the output to the clipboard; accepts file input, piped input or clipboard input
- **`format-json`** - Pretty-print JSON and write the output to stdout; accepts file input, piped input or clipboard input
- **`format-json-clip`** - Pretty-print JSON and write the output to the clipboard; accepts file input, piped input or clipboard input
- **`format-json-file`** - Pretty-print JSON in-place in a file
- **`json-to-spreadsheet`** - Convert JSON to tab-delimited data and open it in a spreadsheet application; accepts file input, piped input or clipboard input
- **`json-to-string`** - Convert JSON to a quoted string; accepts file input, piped input or clipboard input
- **`json-to-string-clip`** - Convert JSON to a quotes string and write the output to the clipboard; accepts file input, piped input or clipboard input
- **`json-to-tsv`** - Convert JSON data to tab-separated values
- **`spacetab`** - Convert between leading tabs and spaces in text; accepts file input, piped input or clipboard input
- **`x2j`** - Convert XML to JSON format

### Git Enhancements
- **`clone`** - Enhanced git clone with automatic setup and navigation
- **`git-blame-colored`** - Enhanced git blame with syntax highlighting
- **`git-lfs`** - Used to work with large files in Git repositories (https://git-lfs.github.com)
- **`git-overwritten`** - Show files that have been overwritten in commits
- **`gr`** - Navigate to git repository root directory
- **`master`** - git checkout master
- **`push`** - git push
- **`undopush`** - Undoes a git push

### Code Utilities
- **`build-classpath`** - Build Java classpath from directory structure
- **`jc`** - Compile Java files with classpath management
- **`jr`** - Run Java applications with proper classpath
- **`lq`** - Submit a query to a LoopBack application
- **`set-values-in-json`** - Set top-level values in a JSON file

## System Administration

### Process Management
- **`killn`** - Kill processes by name pattern matching
- **`killwin` (Windows)** - Kill Windows processes
- **`pscpu`** - List processes sorted by CPU usage
- **`psmem`** - List processes sorted by memory usage
- **`pswin` (Windows)** - List Windows processes

### Network Tools
- **`call-api`** - Call a REST API using curl
- **`get-web-file`** - Gets a web file using wget, curl or lynx
- **`hosts`** - Edit /etc/hosts
- **`ip`** - Show current IP address
- **`localip`** - Display local network IP address
- **`myip`** - Display external IP address
- **`ports`** - Show listening network ports
- **`print-web-file`** - Prints the contents of a web file using wget, curl or lynx
- **`winip` (Windows)** - Print ipconfig address information in a format similar to ifconfig
- **REST API Functions**:
  - **`GET`** - HTTP GET requests with formatting
  - **`POST`** - HTTP POST requests with JSON support
  - **`PUT`** - HTTP PUT requests
  - **`DELETE`** - HTTP DELETE requests

### System Utilities
- **`bounce-wifi` (Windows)** - Restart wireless network interface
- **`burn` (Mac)** - Burn a disc image to a CD/DVD/Blu-Ray without verification
- **`eject` (Mac)** - Eject a disc
- **`empty_trash` (Mac)** - Empty the Trash on all mounted volumes and the main drive and clears sleepimage
- **`hide_desktop` (Mac)** - Hide all desktop icons
- **`hide_files` (Mac)** - Cause Finder to hide hidden files (normal behavior, can also do with
  Cmd + Shift + .)
- **`mount-drive` (Windows)** - Mount a drive
- **`shell_switch` (Mac)** - Switch to the designated shell
- **`show_desktop` (Mac)** - Restore normal desktop icon display
- **`show_files` (Mac)** - Cause Finder to display hidden files (can also do with Cmd + Shift + .)
- **`update-brew` (Mac)** - Update Homebrew and formula definitions, upgrade installed packages, remove old downloads/cache files/unneeded dependencies, and check for potential issues
- **`vburn` (Mac)** - Burn a disc image to a CD/DVD/Blu-Ray with verification

### System Information
- **`camera_used_by` (Mac)** - Check to see which apps are using the camera
- **`disks`** - Display mounted filesystem information
- **`distro`** - Detect and display Linux distribution information
- **`lsusb` (Mac)** - List USB devices
- **`path`** - Show paths in PATH with each directory on a single line
- **`setnf`** - Show values of environment variables and function definitions (with the function contents suppressed)
- **`win_env` (Windows)** - Get the value of a Windows environment variable
- **`win_path_env` (Windows)** - Get the value of a Windows environment variable and convert it to a Linux path

### Security/Hashing
- **`sha1`** - Generate a SHA1 checksum for text data
- **`sha1bin`** - Generate a SHA1 checksum for binary data
- **`sha256`** - Generate a SHA256 checksum for text data
- **`sha256bin`** - Generate a SHA256 checksum for binary data

## Additional Utilities

### Calculation/Conversion
- **`clip2png`** - Saves an image in the clipboard as a PNG file
- **`gifify` (Mac)** - Convert a video to an animated GIF
- **`h2d`** - Convert hexadecimal number to decimal
- **`html2pdf`** - Converts HTML files to PDF
- **`m`** - Evaluate a mathematical expression
- **`png2text`** - Converts a PNG image to text
- **`random`** - Echo a random value between a lower and upper bound
- **`roll`** - Evaluate a dice notation expression
- **`rolln`** - Evaluate a dice notation expression an arbitrary number of times
- **`webmify` (Mac)** - Convert a video into the webm format

### Utilities
- **`clear-recent` (Windows)** - Clear frequent places and recent items
- **`cls`** - Clear the screen
- **`h`** - History
- **`keyhelp`** - Show keyboard shortcut information
- **`now`** - Print current time
- **`nullify`** - Direct all output for a command to /dev/null
- **`stage-roperdot`** - Stage roperdot to Github

### Clipboard Integration
- **`clipcopy`** - Copy text to system clipboard
- **`clippaste`** - Paste text from system clipboard
- **`clip2file`** - Save clipboard contents to file

### Encoding and Encryption
- **`decode-base64`** - Base64 decode text or files
- **`decrypt`** - Decrypt encrypted files
- **`encode-base64`** - Base64 encode text or files
- **`encrypt`** - Encrypt files using available encryption tools
- **`urlencode`** - URL encode text strings
- **`urldecode`** - URL decode text strings

### Color and Display
- **`choose-scheme`** - Interactive color scheme selection for all applications
- **`compare-colors`** - Compare color schemes side by side
- **`compare-color-scheme`** - Print colors defined for a color scheme
- **`gen-all-color-schemes`** - Call gen-color-files for each available color scheme
- **`gen-color-files`** - Generate color files for a color scheme
- **`generate-dircolors`** - Generate .dircolors from a source file
- **`rgb2xterm256`** - Convert an RGB color to an xterm-256 color
- **`show-colormap`** - Display a map of terminal colors
- **`test-dircolors`** - Creates sample files for testing .dircolors
- **`xterm-color-count`** - Display terminal color capabilities

### Configuration
- **`unload-roperdot`** - Resets ~/.dircolors and ~/.vimrc to their contents before roperdot was started
- **`update-app-binaries`** - Updates ~/.roperdot-os-functions and app binaries for the current OS
- **`update-vscode-settings`** - Updates Visual Studio Code settings.json for the color scheme
**NAME**
>cd - change to a directory

**SYNOPSIS**
>cd [_DIRECTORY_]

**Roperdot customizations**
If no arguments are passed and the clipboard contains a directory name, cd will change to that directory.

If gum or fzf is installed:

* If no target is given or if the target is ".", cd will prompt the user to select a subdirectory of the current directory to change to.

* If the target is a pattern, cd will prompt the user to select a matching directory. If only one directory matches, cd will change to that directory.

If the target is an archive, it will be expanded to a temporary directory and cd will change to that directory.

If you're on MacOS and you cd to a dmg file, the dmg will be mounted and cd will change to the mount directory.

If you're on Ubuntu or Mint and you cd to an iso file, the file will be mounted.

If cd is called by another function or if data is piped to it, then it will execute cd without any custom behavior.

Longer dot sequences are supported by this command, e.g. ... is two directories up, .... is three directories up, etc.

Note that the roperdot custom behavior is implemented via a function called by an alias, so it will not impact the command if it's called in a script.
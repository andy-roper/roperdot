**Roperdot customizations**

Symlink directory resolution: when **ls** is given a directory symlink as an argument, it shows the contents of the target directory instead of the symlink itself.

When arguments include non-directory items (files), the _-d_ flag is automatically added to suppress single-level recursion into directories.

Longer dot sequences are supported by this command, e.g. ... is two directories up, .... is three directories up, etc.

Note that the roperdot custom behavior is implemented via a function called by an alias, so it will not impact the command if it's called in a script.
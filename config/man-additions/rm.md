**Roperdot customizations**

The _*_ glob pattern matches both regular and hidden files (those starting with _._).

**WARNING**
Be especially careful with "rm *" since it will remove hidden files too.

Longer dot sequences are supported by this command, e.g. ... is two directories up, .... is three directories up, etc.

Note that the roperdot custom behavior is implemented via a function called by an alias, so it will not impact the command if it's called in a script.
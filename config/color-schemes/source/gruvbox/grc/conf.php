# this configuration file is suitable for displaying php error log files
regexp=\] PHP [^\s]+ error:
colours="\033[38;5;;48;5;166m"
count=once
======
regexp=\] PHP Notice:
colours="\033[38;5;230;48;5;178m"
count=once
======
regexp=\] PHP Warning:
colours="\033[38;5;;48;5;108m"
count=once
======
regexp=(PHP )?Stack trace:
colours="\033[38;5;;48;5;142m"
count=once
======
regexp=] PHP [ \d]{2}\d\.
colours="\033[38;5;;48;5;142m"
count=once
======
# display this line in yellow and stop further processing
regexp=.*last message repeated \d+ times$
colours="\033[38;5;178m"
count=stop
======
# this is date
regexp=^... (\d| )\d \d\d:\d\d:\d\d(\s[\w\d]+?\s)
colours="\033[38;5;142m","\033[38;5;142m","\033[38;5;166m"
count=once
======
# everything in parentheses
regexp=\(.+?\)
colours="\033[38;5;142m"
count=more
======
# everything in `'
regexp=\`.+?\'
colours="\033[01;38;5;178m"
count=more
======
# this is probably a pathname
regexp=/[\w/\.]+
colours="\033[01;38;5;142m"
count=more
======
# name of process and pid
regexp=([\w/\.\-]+)(\[\d+?\])
colours="\033[01;38;5;66m","\033[01;38;5;166m"
count=more
======
# ip number
regexp=\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}
colours="\033[01;38;5;138m"
count=more
======
# connect requires special attention
regexp=connect
colours="\033[38;5;;48;5;166m"
count=more
======
regexp=not found or unable to stat
colours="\033[38;5;230m"
count=block
======
regexp=File does not exist
colours="\033[38;5;m"
count=block
======
regexp=^\[
colours=default
count=unblock


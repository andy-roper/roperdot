# The following matches file sizes as produced by ls -l or ls -lh
# The output produced by ls -s is probably not specific
# enough to be reliably matched, especially considering ls -s(k|m|g|G).
#
# Example lines:
# -rw-r--r--   1 user staff 344M Mar 22 22:51 MVI_8735.m4v
# -rw-r--r--   1 user staff 360050327 Mar 22 22:51 MVI_8735.m4v
# -rw-r--r--.  1 user staff 1.0G Nov 23 16:13 testg
# -rw-r--r--.  1 user staff 1.0K Nov 23 16:13 testk
# -rw-r--r--.  1 user staff 1.0M Nov 23 16:13 testm
# -rw-r--r--.  1 user staff 1073741824 Nov 23 16:13 testg
# -rw-r--r--.  1 user staff       1024 Nov 23 16:13 testk
# -rw-r--r--.  1 user staff    1048576 Nov 23 16:13 testm
#
# The regexp uses lookahead to match a date following the size

# size: 1M <= size < 10M
regexp=\s+(\d{7}|\d(?:[,.]?\d+)?[KM])(?=\s[A-Z][a-z]{2}\s)
colours="\033[38;5;142m"
=======
# size: 10M <= size < 100M
regexp=\s+(\d{8}|\d\d(?:[,.]?\d+)?M)(?=\s[A-Z][a-z]{2}\s)
colours="\033[38;5;178m"
=======
# size: 100M <= size < 1G
regexp=\s+(\d{9}|\d{3}M)(?=\s[A-Z][a-z]{2}\s)
colours="\033[38;5;166m"
=======
# size: 1G <= size
regexp=\s+(\d{10,}|[\d.,]+G)(?=\s[A-Z][a-z]{2}\s)
colours="\033[01;38;5;166m"
=======
# device major minor numbers
regexp=\s(\d+),\s+(\d+)\s
colours=default,"\033[38;5;136m","\033[38;5;178m"
=======
# Date-Time => G1=Month G2=Day G3=Hour G4=Minutes G5=Year
regexp=([A-Z][a-z]{2})\s([ 1-3]\d)\s(?:([0-2]?\d):([0-5]\d)(?=[\s,]|$)|\s*(\d{4}))
colours=unchanged,"\033[38;5;108m","\033[38;5;108m","\033[38;5;108m","\033[38;5;108m","\033[01;38;5;138m"
=======
# root
regexp=\s(root|wheel)(?=\s|$)
colours=unchanged,"\033[01;38;5;102;48;5;166m"
=======
# SELinux
regexp=(\w+_u):(\w+_r):(\w+_t):(\w\d)
colours=default,"\033[38;5;142m","\033[38;5;178m","\033[38;5;108m","\033[38;5;138m"
-
# -rwxrwxrwx ============================
# File Type
regexp=(-|([bcCdDlMnpPs?]))(?=[-r][-w][-xsStT][-r][-w][-xsStT][-r][-w][-xsStT])
colours=unchanged,unchanged,"\033[01;38;5;102m"
-
# owner rwx
regexp=(?<=[-bcCdDlMnpPs?])(-|(r))(-|(w))(-|([xsStT]))(?=[-r][-w][-xsStT][-r][-w][-xsStT])
colours=unchanged,unchanged,"\033[38;5;100m",unchanged,"\033[38;5;100m",unchanged,"\033[38;5;100m"
-
# group rwx
regexp=(?<=[-bcCdDlMnpPs?][-r][-w][-xsStT])(-|(r))(-|(w))(-|([xsStT]))(?=[-r][-w][-xsStT])
colours=unchanged,unchanged,"\033[38;5;178m",unchanged,"\033[38;5;178m",unchanged,"\033[38;5;178m"
-
# other rwx
regexp=(?<=[-bcCdDlMnpPs?][-r][-w][-xsStT][-r][-w][-xsStT])(-|(r))(-|(w))(-|([xsStT]))
colours=unchanged,unchanged,"\033[38;5;124m",unchanged,"\033[38;5;124m",unchanged,"\033[38;5;124m"
-
# sStT all
regexp=(?<=[-bcCdDlMnpPs?])[-r][-w]([sStT])[-r][-w]([sStT])[-r][-w]([sStT])
colours=unchanged,"\033[01;38;5;142m","\033[01;38;5;178m","\033[01;38;5;166m"
-
# ACL
regexp=^\S{10}(\+)
colours=unchanged,"\033[01;38;5;102;48;5;108m"
=======
# Date-Time long-iso
regexp=(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d)
colours="\033[38;5;108m","\033[38;5;108m","\033[38;5;108m","\033[38;5;108m","\033[38;5;108m"

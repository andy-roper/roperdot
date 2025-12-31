# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;100m","\033[38;5;124m","\033[38;5;108m","\033[38;5;138m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;142m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;138m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;178m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;66m"
=======
# status UNCONN
regexp=UNCONN
colours="\033[38;5;166m"
=======
# status
regexp=FIN_WAIT.*
colours="\033[38;5;166m"
=======
# status
regexp=SYN.*?
colours="\033[01;38;5;166m"
=======
# status
regexp=LISTEN(ING)?
colours="\033[01;38;5;66m"
=======
# status
regexp=TIME_WAIT
colours="\033[01;38;5;166m"
=======
# status
regexp=CLOS(E(_WAIT)?|ING)
colours="\033[38;5;166m"
skip=yes
=======
# status
regexp=LAST_ACK
colours="\033[38;5;166m"
=======
# status
regexp=ESTAB.*?\b|CONNECTED
colours="\033[01;38;5;178m"
=======
# status
regexp=FREE
colours="\033[01;38;5;142m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;166m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;142m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;166m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;142m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;142m","\033[01;38;5;142m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;178m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

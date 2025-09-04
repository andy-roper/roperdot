# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;78m","\033[38;5;203m","\033[38;5;36m","\033[38;5;133m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;35m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;133m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;214m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;68m"
=======
# status UNCONN
regexp=UNCONN
colours="\033[38;5;167m"
=======
# status
regexp=FIN_WAIT.*
colours="\033[38;5;167m"
=======
# status
regexp=SYN.*?
colours="\033[01;38;5;167m"
=======
# status
regexp=LISTEN(ING)?
colours="\033[01;38;5;68m"
=======
# status
regexp=TIME_WAIT
colours="\033[01;38;5;167m"
=======
# status
regexp=CLOS(E(_WAIT)?|ING)
colours="\033[38;5;167m"
skip=yes
=======
# status
regexp=LAST_ACK
colours="\033[38;5;167m"
=======
# status
regexp=ESTAB.*?\b|CONNECTED
colours="\033[01;38;5;214m"
=======
# status
regexp=FREE
colours="\033[01;38;5;35m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;167m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;35m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;167m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;35m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;35m","\033[01;38;5;35m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;214m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

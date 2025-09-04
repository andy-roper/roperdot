# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;143m","\033[38;5;203m","\033[38;5;66m","\033[38;5;96m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;101m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;96m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;173m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;60m"
=======
# status UNCONN
regexp=UNCONN
colours="\033[38;5;131m"
=======
# status
regexp=FIN_WAIT.*
colours="\033[38;5;131m"
=======
# status
regexp=SYN.*?
colours="\033[01;38;5;131m"
=======
# status
regexp=LISTEN(ING)?
colours="\033[01;38;5;60m"
=======
# status
regexp=TIME_WAIT
colours="\033[01;38;5;131m"
=======
# status
regexp=CLOS(E(_WAIT)?|ING)
colours="\033[38;5;131m"
skip=yes
=======
# status
regexp=LAST_ACK
colours="\033[38;5;131m"
=======
# status
regexp=ESTAB.*?\b|CONNECTED
colours="\033[01;38;5;173m"
=======
# status
regexp=FREE
colours="\033[01;38;5;101m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;131m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;101m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;131m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;101m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;101m","\033[01;38;5;101m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;173m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

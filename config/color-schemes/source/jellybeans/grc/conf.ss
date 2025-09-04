# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;187m","\033[38;5;217m","\033[38;5;37m","\033[38;5;189m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;144m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;189m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;222m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;152m"
=======
# status UNCONN
regexp=UNCONN
colours="\033[38;5;174m"
=======
# status
regexp=FIN_WAIT.*
colours="\033[38;5;174m"
=======
# status
regexp=SYN.*?
colours="\033[01;38;5;174m"
=======
# status
regexp=LISTEN(ING)?
colours="\033[01;38;5;152m"
=======
# status
regexp=TIME_WAIT
colours="\033[01;38;5;174m"
=======
# status
regexp=CLOS(E(_WAIT)?|ING)
colours="\033[38;5;174m"
skip=yes
=======
# status
regexp=LAST_ACK
colours="\033[38;5;174m"
=======
# status
regexp=ESTAB.*?\b|CONNECTED
colours="\033[01;38;5;222m"
=======
# status
regexp=FREE
colours="\033[01;38;5;144m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;174m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;144m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;174m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;144m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;144m","\033[01;38;5;144m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;222m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

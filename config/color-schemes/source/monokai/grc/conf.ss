# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;148m","\033[38;5;198m","\033[38;5;73m","\033[38;5;99m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;106m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;99m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;185m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;74m"
=======
# status UNCONN
regexp=UNCONN
colours="\033[38;5;161m"
=======
# status
regexp=FIN_WAIT.*
colours="\033[38;5;161m"
=======
# status
regexp=SYN.*?
colours="\033[01;38;5;161m"
=======
# status
regexp=LISTEN(ING)?
colours="\033[01;38;5;74m"
=======
# status
regexp=TIME_WAIT
colours="\033[01;38;5;161m"
=======
# status
regexp=CLOS(E(_WAIT)?|ING)
colours="\033[38;5;161m"
skip=yes
=======
# status
regexp=LAST_ACK
colours="\033[38;5;161m"
=======
# status
regexp=ESTAB.*?\b|CONNECTED
colours="\033[01;38;5;185m"
=======
# status
regexp=FREE
colours="\033[01;38;5;106m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;161m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;106m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;161m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;106m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;106m","\033[01;38;5;106m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;185m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

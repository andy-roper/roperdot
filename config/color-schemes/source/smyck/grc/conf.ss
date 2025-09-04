# Local Address:Port
regexp=\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)\s+\s((?:\d+\.){3}\d+|\*|::1?|[\w\d\-\_\.]+):(\S+)
colours=default,"\033[38;5;192m","\033[38;5;181m","\033[38;5;31m","\033[38;5;182m"
=======
# ipx hostname
regexp=^IPX.*[\dABCDEF]+:[\dABCDEF]+
colours="\033[38;5;143m"
=======
# protocols
regexp=(^tcp|^udp|^unix|^IPX|STREAM|DGRAM)
colours="\033[38;5;182m"
=======
# protocols UDP
regexp=^udp
colours="\033[38;5;179m"
=======
# protocols TCP
regexp=^tcp
colours="\033[38;5;110m"
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
colours="\033[01;38;5;110m"
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
colours="\033[01;38;5;179m"
=======
# status
regexp=FREE
colours="\033[01;38;5;143m"
=======
# status
regexp=DISCONNECTING
colours="\033[38;5;167m"
=======
# status
regexp=CONNECTING
colours="\033[38;5;143m"
=======
# status
regexp=UNKNOWN
colours="\033[01;05;38;5;167m"
=======
# status
regexp=\[.*\]
colours="\033[38;5;143m"
=======
# path
regexp=(\@)[\dabcdef]+
colours="\033[38;5;143m","\033[01;38;5;143m"
=======
# timer
regexp=\d+sec
colours="\033[38;5;179m"
=======
#Skip header
regexp=(Netid|State).*$
colours=default

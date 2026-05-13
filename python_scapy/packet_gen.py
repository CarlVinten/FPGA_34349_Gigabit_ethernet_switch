from scapy.all import *
a = (Ether()/IP()/TCP())
print(raw(a))
print(hexdump(a))
from scapy.all import *
import binascii




ieee_frame = Dot3(dst="00:11:22:33:44:55", src="00:66:77:88:99:AA") / LLC() / "Data"


wrpcap("pack1.cap", ieee_frame)
preamble = str(([0xAA] * 7))
f_out = open("packet_out", "w")

f_out.write()
with open("pack1.cap", "rb") as fd:
    content = fd.read()
    for byte in content:
        # '08b' formats the integer as a bit string, 8 bits long, padded with zeros
        print((format(byte, '02x')), end="", file = f_out)
        

        



'''
wrpcap("python_scapy/pack1.cap", ieee_frame)
fd = open("python_scapy/pack1.cap", "rb")
for line in fd:
	for word in line:
		print(word)
b = bytes(ieee_frame)
fcs = binascii.crc32(b) & 0xFFFFFFFF
print(b)
print((ieee_frame))
print((hex(fcs)))
'''





'''

a = (Ether()/IP()/TCP())
print(raw(a))
print(hexdump(a))
'''
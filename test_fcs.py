#!/usr/bin/env python3
import struct

# Build CRC table
def build_crc_table():
    table = []
    poly = 0xEDB88320
    for i in range(256):
        crc = i
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc & 0xffffffff)
    return table

def calc_fcs(data, table):
    crc = 0xffffffff
    for byte in data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc ^ 0xffffffff

# Test with the working packet's frame data (without preamble and FCS)
table = build_crc_table()
working_frame = bytes([
    0x00, 0x10, 0xA4, 0x7B, 0xEA, 0x80, 0x00, 0x12,
    0x34, 0x56, 0x78, 0x90, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x2E, 0xB3, 0xFE, 0x00, 0x00, 0x80, 0x11,
    0x05, 0x40, 0xC0, 0xA8, 0x00, 0x2C, 0xC0, 0xA8,
    0x00, 0x04, 0x04, 0x00, 0x04, 0x00, 0x00, 0x1A,
    0x2D, 0xE8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, 0x0F, 0x10, 0x11
])

fcs = calc_fcs(working_frame, table)
print(f'Calculated FCS (hex): {fcs:08X}')
print(f'Calculated FCS (big-endian bytes): {struct.pack(">I", fcs).hex().upper()}')
print(f'Calculated FCS (little-endian bytes): {struct.pack("<I", fcs).hex().upper()}')
print(f'Expected FCS from working packet: E6C53DB2')
print()
print("This will show if the issue is byte order or the calculation method itself")

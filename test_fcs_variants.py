#!/usr/bin/env python3
import struct

def reverse_bits(value, width):
    """Reverse bits in a value"""
    result = 0
    for i in range(width):
        result = (result << 1) | (value & 1)
        value >>= 1
    return result

def build_crc_table_standard():
    """Standard Ethernet CRC lookup table"""
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

def build_crc_table_bit_reversed():
    """CRC table with bit-reversed input/output"""
    table = []
    poly = 0x04C11DB7  # Normal (non-reflected) polynomial
    for i in range(256):
        crc = reverse_bits(i, 8) << 24
        for _ in range(8):
            if crc & 0x80000000:
                crc = ((crc << 1) ^ poly) & 0xffffffff
            else:
                crc = (crc << 1) & 0xffffffff
        table.append(reverse_bits(crc, 32))
    return table

def calc_fcs_standard(data, table):
    """Standard CRC-32"""
    crc = 0xffffffff
    for byte in data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc ^ 0xffffffff

def calc_fcs_bit_reversed(data, table):
    """CRC-32 with bit reversal"""
    crc = 0xffffffff
    for byte in data:
        byte = reverse_bits(byte, 8)
        index = ((crc >> 24) ^ byte) & 0xff
        crc = ((crc << 8) ^ table[index]) & 0xffffffff
    return reverse_bits(crc ^ 0xffffffff, 32)

# Test frame data (without preamble and FCS)
test_frame = bytes([
    0x00, 0x10, 0xA4, 0x7B, 0xEA, 0x80, 0x00, 0x12,
    0x34, 0x56, 0x78, 0x90, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x2E, 0xB3, 0xFE, 0x00, 0x00, 0x80, 0x11,
    0x05, 0x40, 0xC0, 0xA8, 0x00, 0x2C, 0xC0, 0xA8,
    0x00, 0x04, 0x04, 0x00, 0x04, 0x00, 0x00, 0x1A,
    0x2D, 0xE8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, 0x0F, 0x10, 0x11
])

print("Expected FCS: E6C53DB2")
print()

# Try standard algorithm
table_std = build_crc_table_standard()
fcs_std = calc_fcs_standard(test_frame, table_std)
print(f"Standard CRC: {fcs_std:08X}")
print(f"  Big-endian: {struct.pack('>I', fcs_std).hex().upper()}")
print(f"  Little-endian: {struct.pack('<I', fcs_std).hex().upper()}")
print()

# Try bit-reversed algorithm
table_rev = build_crc_table_bit_reversed()
fcs_rev = calc_fcs_bit_reversed(test_frame, table_rev)
print(f"Bit-Reversed CRC: {fcs_rev:08X}")
print(f"  Big-endian: {struct.pack('>I', fcs_rev).hex().upper()}")
print(f"  Little-endian: {struct.pack('<I', fcs_rev).hex().upper()}")

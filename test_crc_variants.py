#!/usr/bin/env python3
"""Test various CRC configurations"""

def build_crc_table(poly=0xEDB88320):
    table = []
    for i in range(256):
        crc = i
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
        table.append(crc & 0xffffffff)
    return table

def build_crc_table_reflected(poly=0x04C11DB7):
    """Unreflected polynomial"""
    table = []
    for i in range(256):
        crc = i << 24
        for _ in range(8):
            if crc & 0x80000000:
                crc = ((crc << 1) ^ poly) & 0xffffffff
            else:
                crc = (crc << 1) & 0xffffffff
        table.append(crc)
    return table

def calc_crc_standard(data, init=0xffffffff, xor_out=0xffffffff):
    """Standard CRC-32"""
    table = build_crc_table()
    crc = init
    for byte in data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc ^ xor_out

def calc_crc_itu(data, init=0xffffffff, xor_out=0xffffffff):
    """CRC-32-ITU (unreflected)"""
    table = build_crc_table_reflected()
    crc = init
    for byte in data:
        index = ((crc >> 24) ^ byte) & 0xff
        crc = ((crc << 8) ^ table[index]) & 0xffffffff
    return crc ^ xor_out

frame_data = bytes([
    0x00, 0x10, 0xA4, 0x7B, 0xEA, 0x80, 0x00, 0x12,
    0x34, 0x56, 0x78, 0x90, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x2E, 0xB3, 0xFE, 0x00, 0x00, 0x80, 0x11,
    0x05, 0x40, 0xC0, 0xA8, 0x00, 0x2C, 0xC0, 0xA8,
    0x00, 0x04, 0x04, 0x00, 0x04, 0x00, 0x00, 0x1A,
    0x2D, 0xE8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, 0x0F, 0x10, 0x11
])

working_fcs = bytes([0xE6, 0xC5, 0x3D, 0xB2])

print("Testing various CRC configurations:")
print("=" * 60)

# Test different XOR values
for xor_out in [0x00000000, 0xFFFFFFFF]:
    fcs = calc_crc_standard(frame_data, xor_out=xor_out)
    fcs_bytes = fcs.to_bytes(4, 'big')
    print(f"Standard CRC (XOR={xor_out:08X}): {' '.join(f'{b:02X}' for b in fcs_bytes)}")
    if fcs_bytes == working_fcs:
        print("  ✓ MATCH!")

# Test ITU-T CRC
fcs_itu = calc_crc_itu(frame_data, xor_out=0xffffffff)
fcs_itu_bytes = fcs_itu.to_bytes(4, 'big')
print(f"CRC-32-ITU:                 {' '.join(f'{b:02X}' for b in fcs_itu_bytes)}")
if fcs_itu_bytes == working_fcs:
    print("  ✓ MATCH!")

print(f"\nTarget FCS: {' '.join(f'{b:02X}' for b in working_fcs)}")

# Try with byte reversal
fcs_std = calc_crc_standard(frame_data)
fcs_reversed = bytes(reversed(fcs_std.to_bytes(4, 'big')))
print(f"Standard CRC (byte-reversed): {' '.join(f'{b:02X}' for b in fcs_reversed)}")
if fcs_reversed == working_fcs:
    print("  ✓ MATCH!")

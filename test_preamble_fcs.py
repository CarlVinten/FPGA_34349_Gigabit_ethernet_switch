#!/usr/bin/env python3
"""Test if preamble is included in FCS"""

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

def calc_crc_normal(data):
    """Standard CRC-32 (no inversion)"""
    table = build_crc_table()
    crc = 0xffffffff
    for byte in data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc ^ 0xffffffff

preamble = bytes([0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB])

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

print("Testing with preamble included:")
print("=" * 60)

# Test 1: Just frame data
fcs_frame_only = calc_crc_normal(frame_data)
fcs_frame_only_bytes = fcs_frame_only.to_bytes(4, 'big')
print(f"CRC of frame data only: {' '.join(f'{b:02X}' for b in fcs_frame_only_bytes)}")

# Test 2: Preamble + frame data
fcs_with_preamble = calc_crc_normal(preamble + frame_data)
fcs_with_preamble_bytes = fcs_with_preamble.to_bytes(4, 'big')
print(f"CRC of preamble + frame: {' '.join(f'{b:02X}' for b in fcs_with_preamble_bytes)}")

print(f"\nWorking FCS:            {' '.join(f'{b:02X}' for b in working_fcs)}")

# Maybe the FCS is calculated on preamble + frame and then inverted?
inverted_fcs = bytes([(b ^ 0xFF) for b in fcs_with_preamble_bytes])
print(f"CRC XOR 0xFFFFFFFF:     {' '.join(f'{b:02X}' for b in inverted_fcs)}")

# Or maybe it's in little-endian?
fcs_le = fcs_with_preamble_bytes[::-1]
print(f"CRC (little-endian):    {' '.join(f'{b:02X}' for b in fcs_le)}")

# Test different init values
table = build_crc_table()
for init in [0x00000000, 0xFFFFFFFF]:
    crc = init
    for byte in preamble + frame_data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    fcs_bytes = (crc ^ 0xffffffff).to_bytes(4, 'big')
    print(f"CRC (init={init:08X}): {' '.join(f'{b:02X}' for b in fcs_bytes)}")

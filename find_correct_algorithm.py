#!/usr/bin/env python3
"""Reverse-engineer the correct FCS algorithm"""

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

def calc_crc_inverted(data):
    """CRC with all bytes inverted"""
    table = build_crc_table()
    crc = 0xffffffff
    for byte in data:
        inverted = byte ^ 0xFF
        index = (crc ^ inverted) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc ^ 0xffffffff

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

print("Testing FCS algorithms:")
print("=" * 60)

# Test standard CRC
fcs_normal = calc_crc_normal(frame_data)
fcs_normal_bytes = fcs_normal.to_bytes(4, 'big')
print(f"Standard CRC (no inversion): {' '.join(f'{b:02X}' for b in fcs_normal_bytes)}")
print(f"  Match: {fcs_normal_bytes == working_fcs}")

# Test inverted CRC
fcs_inverted = calc_crc_inverted(frame_data)
fcs_inverted_bytes = fcs_inverted.to_bytes(4, 'big')
print(f"Inverted CRC (all bytes): {' '.join(f'{b:02X}' for b in fcs_inverted_bytes)}")
print(f"  Match: {fcs_inverted_bytes == working_fcs}")

print("\n" + "=" * 60)
print(f"Working FCS: {' '.join(f'{b:02X}' for b in working_fcs)}")

# Also test what these produce when processed through the frame
table = build_crc_table()

# Test with working FCS
full_frame = frame_data + working_fcs
crc_normal = 0xffffffff
for byte in full_frame:
    index = (crc_normal ^ byte) & 0xff
    crc_normal = (crc_normal >> 8) ^ table[index]
crc_normal ^= 0xffffffff
print(f"\nFull frame with working FCS processed (normal): {crc_normal:08X}")

# Test with working FCS inverted
crc_inverted = 0xffffffff
for byte in full_frame:
    inverted = byte ^ 0xFF
    index = (crc_inverted ^ inverted) & 0xff
    crc_inverted = (crc_inverted >> 8) ^ table[index]
crc_inverted ^= 0xffffffff
print(f"Full frame with working FCS processed (inverted): {crc_inverted:08X}")

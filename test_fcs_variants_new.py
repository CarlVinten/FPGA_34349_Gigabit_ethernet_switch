#!/usr/bin/env python3
"""Test different byte inversion strategies"""

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

def calc_crc_inverted(data, table):
    """Calculate CRC with all bytes inverted"""
    crc = 0xffffffff
    for byte in data:
        inverted_byte = byte ^ 0xFF
        index = (crc ^ inverted_byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc

def calc_crc_normal(data, table):
    """Calculate CRC without inversion"""
    crc = 0xffffffff
    for byte in data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc

frame_data = bytes([  # Everything except preamble and FCS
    0x00, 0x10, 0xA4, 0x7B, 0xEA, 0x80, 0x00, 0x12,
    0x34, 0x56, 0x78, 0x90, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x2E, 0xB3, 0xFE, 0x00, 0x00, 0x80, 0x11,
    0x05, 0x40, 0xC0, 0xA8, 0x00, 0x2C, 0xC0, 0xA8,
    0x00, 0x04, 0x04, 0x00, 0x04, 0x00, 0x00, 0x1A,
    0x2D, 0xE8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, 0x0F, 0x10, 0x11
])

preamble = bytes([0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB])
original_fcs = bytes([0xE6, 0xC5, 0x3D, 0xB2])

table = build_crc_table()

print("Testing different combinations:")
print("=" * 60)

# Test 1: All bytes inverted, including preamble and FCS
full_frame = preamble + frame_data + original_fcs
result = calc_crc_inverted(full_frame, table)
print(f"1. All bytes inverted: {result:08X}")

# Test 2: Only frame data inverted (not preamble), with FCS
data_only_inverted = preamble + frame_data + original_fcs
# Manually calc with partial inversion
crc = 0xffffffff
# Process preamble normally
for byte in preamble:
    index = (crc ^ byte) & 0xff
    crc = (crc >> 8) ^ table[index]
# Process frame data inverted
for byte in frame_data:
    inverted = byte ^ 0xFF
    index = (crc ^ inverted) & 0xff
    crc = (crc >> 8) ^ table[index]
# Process FCS normally
for byte in original_fcs:
    index = (crc ^ byte) & 0xff
    crc = (crc >> 8) ^ table[index]
print(f"2. Preamble normal, data inverted, FCS normal: {crc:08X}")

# Test 3: All normal (no inversion)
full_frame_normal = preamble + frame_data + original_fcs
result_normal = calc_crc_normal(full_frame_normal, table)
print(f"3. All bytes normal: {result_normal:08X}")

# Test 4: Just frame data with original FCS, no preamble
result4 = calc_crc_normal(frame_data + original_fcs, table)
print(f"4. Frame data + FCS (no preamble, normal): {result4:08X}")

result4_inv = calc_crc_inverted(frame_data + original_fcs, table)
print(f"5. Frame data + FCS (no preamble, inverted): {result4_inv:08X}")

print("\n" + "=" * 60)
print("Magic numbers to check for:")
print(f"  0xFFFFFFFF (all ones)")
print(f"  0x2144DF1C (standard Ethernet CRC magic)")
print(f"  0xC704DD7B (standard Ethernet CRC residue)")

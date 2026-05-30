#!/usr/bin/env python3
"""Calculate what FCS produces 0xFFFFFFFF"""

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

def calc_fcs_for_target(frame_data, target=0xFFFFFFFF):
    """Calculate what FCS bytes would produce target CRC"""
    table = build_crc_table()
    
    crc = 0xffffffff
    for byte in frame_data:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    
    # Now we have CRC of frame data without FCS
    # We need to find 4 bytes X such that crc XOR X = target
    # So X = crc XOR target
    fcs_value = crc ^ target
    fcs_bytes = fcs_value.to_bytes(4, 'big')
    
    # Verify
    for byte in fcs_bytes:
        index = (crc ^ byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    
    return fcs_bytes, crc

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

# Calculate FCS for different targets
targets = [
    (0xFFFFFFFF, "all ones"),
    (0x2144DF1C, "standard Ethernet magic (reflected)"),
    (0xC704DD7B, "standard Ethernet residue"),
]

for target, desc in targets:
    fcs, final_crc = calc_fcs_for_target(frame_data, target)
    fcs_hex = " ".join(f"{b:02X}" for b in fcs)
    print(f"Target {desc} ({target:08X}):")
    print(f"  FCS bytes: {fcs_hex}")
    print(f"  Final CRC: {final_crc:08X}")
    print()

# Also show what CRC we're starting with
table = build_crc_table()
crc = 0xffffffff
for byte in frame_data:
    index = (crc ^ byte) & 0xff
    crc = (crc >> 8) ^ table[index]
print(f"CRC of frame data without FCS: {crc:08X}")

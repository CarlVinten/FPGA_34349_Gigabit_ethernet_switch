#!/usr/bin/env python3
"""Verify FCS calculation matches the VHDL checker"""

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

def calc_crc_with_inverted_input(data, table):
    """Calculate CRC with inverted input bytes (like VHDL checker)"""
    crc = 0xffffffff
    for byte in data:
        # Invert the byte to match VHDL's NOT operation
        inverted_byte = byte ^ 0xFF
        index = (crc ^ inverted_byte) & 0xff
        crc = (crc >> 8) ^ table[index]
    return crc

# Test frame data (preamble + MACs + type + IPv4 + UDP + payload)
frame = bytes([
    0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB,  # Preamble
    0x00, 0x10, 0xA4, 0x7B, 0xEA, 0x80, 0x00, 0x12,  # MACs
    0x34, 0x56, 0x78, 0x90, 0x08, 0x00, 0x45, 0x00,  # MACs + EtherType + IPv4
    0x00, 0x2E, 0xB3, 0xFE, 0x00, 0x00, 0x80, 0x11,  # IPv4
    0x05, 0x40, 0xC0, 0xA8, 0x00, 0x2C, 0xC0, 0xA8,  # IPv4
    0x00, 0x04, 0x04, 0x00, 0x04, 0x00, 0x00, 0x1A,  # IPv4 + UDP
    0x2D, 0xE8, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,  # UDP + Payload
    0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,  # Payload
    0x0E, 0x0F, 0x10, 0x11                            # Payload
])

table = build_crc_table()

# Test with original FCS
frame_with_original_fcs = frame + bytes([0xE6, 0xC5, 0x3D, 0xB2])
result_original = calc_crc_with_inverted_input(frame_with_original_fcs, table)
print(f"Frame with original FCS (E6 C5 3D B2) result: {result_original:08X}")

# Test with our calculated FCS
frame_with_new_fcs = frame + bytes([0xEB, 0x16, 0x49, 0xF6])
result_new = calc_crc_with_inverted_input(frame_with_new_fcs, table)
print(f"Frame with new FCS (EB 16 49 F6) result: {result_new:08X}")

# Test what FCS would give us 0xFFFFFFFF
# We need to find FCS such that processing frame + FCS gives 0xFFFFFFFF
# This is equivalent to: the CRC of frame + X should equal 0xFFFFFFFF
# So: crc(frame) XOR crc(X) = 0xFFFFFFFF
# But that's not quite right...

# Actually, the correct way: if we have frame and want to find FCS
# such that crc(frame + FCS) = 0xFFFFFFFF:
# The FCS bytes themselves need to be processed to make this happen

# Simple approach: try to find what 4 bytes would give us the magic number
crc_without_fcs = calc_crc_with_inverted_input(frame, table)
print(f"\nCRC of frame without FCS: {crc_without_fcs:08X}")

# The FCS should be calculated such that it "completes" the CRC to the target
# One common approach: FCS = ~(CRC of frame data)
fcs_complement = (~crc_without_fcs) & 0xffffffff
print(f"If FCS = complement of CRC: {fcs_complement:08X}")
frame_with_complement = frame + fcs_complement.to_bytes(4, 'big')
result_complement = calc_crc_with_inverted_input(frame_with_complement, table)
print(f"Result with complement FCS: {result_complement:08X}")

print(f"\nTarget result: FFFFFFFF")

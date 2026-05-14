import binascii
import struct
import os
from scapy.all import Ether, IP, UDP, raw

def generate_fpga_test_vector(pkt, include_preamble=True):
    # 1. Get raw bytes of MAC frame
    raw_bytes = raw(pkt)
    
    # 2. Pad to 60 bytes if needed
    if len(raw_bytes) < 60:
        raw_bytes += b'\x00' * (60 - len(raw_bytes))
        
    # 3. Calculate FCS
    fcs = binascii.crc32(raw_bytes) & 0xffffffff
    
    # 4. Append FCS
    frame_with_fcs = raw_bytes + struct.pack('<I', fcs)
    
    # 5. Prepend Preamble/SFD if needed
    if include_preamble:
        preamble_sfd = b'\x55\x55\x55\x55\x55\x55\x55\xd5'
        final_frame = preamble_sfd + frame_with_fcs
    else:
        final_frame = frame_with_fcs
    
    # 6. Format to XX_XX_XX...
    hex_string = final_frame.hex().upper()
    formatted_hex = '_'.join(hex_string[i:i+2] for i in range(0, len(hex_string), 2))
    
    return formatted_hex

# Create a folder to store the output so it doesn't clutter your directory
output_dir = "fpga_test_packets"
os.makedirs(output_dir, exist_ok=True)

print(f"Generating 10 packets and saving them to the '{output_dir}' folder...\n")

for i in range(1, 11):
    target_ip = f"192.168.1.{200 + i}"
    target_port = 8000 + i
    payload_data = f"FPGA_TEST_PACKET_NUM_{i:02d}".encode('utf-8')

    # Build the packet using Scapy
    pkt = Ether(dst="00:10:A4:7B:EA:80", src="00:12:34:56:78:90") / \
          IP(src="192.168.1.100", dst=target_ip) / \
          UDP(sport=5000, dport=target_port) / \
          payload_data

    # Generate the hex string (with preamble and CRC)
    hex_output = generate_fpga_test_vector(pkt, include_preamble=True)
    
    # Define filename like packet_01.txt, packet_02.txt
    filename = os.path.join(output_dir, f"packet_{i:02d}.txt")
    
    # Write the formatted string to the file
    with open(filename, 'w') as f:
        f.write(hex_output)
        
    print(f"Successfully saved {filename}")

print("\nDone! You can now load these files directly into your testbench.")
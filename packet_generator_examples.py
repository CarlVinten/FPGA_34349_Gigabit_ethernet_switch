#!/usr/bin/env python3
"""
Examples for using the Ethernet Packet Generator
"""

from ethernet_packet_generator import EthernetPacketGenerator

def example_1_basic():
    """Example 1: Generate a basic packet with default settings"""
    print("=" * 60)
    print("Example 1: Basic Packet Generation")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    
    # Create a frame with default parameters
    frame = gen.create_frame()
    
    # Display as VHDL
    vhdl_code = gen.frame_to_vhdl_formatted(frame, "BASIC_FRAME")
    print(vhdl_code)
    print()


def example_2_custom_macs():
    """Example 2: Custom MAC addresses"""
    print("=" * 60)
    print("Example 2: Custom MAC Addresses")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    
    # Create a frame with custom MAC addresses
    frame = gen.create_frame(
        dst_mac="FF:FF:FF:FF:FF:FF",  # Broadcast
        src_mac="00:AA:BB:CC:DD:EE"
    )
    
    # Display as VHDL
    vhdl_code = gen.frame_to_vhdl_formatted(frame, "BROADCAST_FRAME")
    print(vhdl_code)
    print()


def example_3_custom_payload():
    """Example 3: Custom payload"""
    print("=" * 60)
    print("Example 3: Custom Payload")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    
    # Create frame with custom hex payload
    custom_payload = "45 00 00 2E B3 FE 00 00 80 11 05 40 C0 A8 00 2C C0 A8 00 04"
    frame = gen.create_frame(
        payload_hex_string=custom_payload
    )
    
    # Display as VHDL
    vhdl_code = gen.frame_to_vhdl_formatted(frame, "CUSTOM_PAYLOAD_FRAME")
    print(vhdl_code)
    print()


def example_4_ipv4_packet():
    """Example 4: IPv4 UDP packet"""
    print("=" * 60)
    print("Example 4: IPv4 UDP Packet")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    
    # IPv4 header + UDP data
    ipv4_udp_payload = (
        "45 00 00 2E B3 FE 00 00 80 11 05 40 C0 A8 00 2C C0 A8 00 04 "
        "04 00 04 00 00 1A 2D E8 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"
    )
    
    frame = gen.create_frame(
        dst_mac="00:10:A4:7B:EA:80",
        src_mac="00:12:34:56:78:90",
        eth_type=0x0800,  # IPv4
        payload_hex_string=ipv4_udp_payload
    )
    
    # Display as VHDL
    vhdl_code = gen.frame_to_vhdl_formatted(frame, "IPV4_UDP_FRAME")
    print(vhdl_code)
    print()


def example_5_save_to_file():
    """Example 5: Save packets to files"""
    print("=" * 60)
    print("Example 5: Saving Packets to Files")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    
    # Generate multiple packets
    packets = [
        {
            'name': 'packet_01',
            'dst_mac': '00:10:A4:7B:EA:80',
            'src_mac': '00:12:34:56:78:90',
            'const_name': 'ETHERNET_FRAME_1'
        },
        {
            'name': 'packet_02',
            'dst_mac': 'FF:FF:FF:FF:FF:FF',  # Broadcast
            'src_mac': '00:AA:BB:CC:DD:EE',
            'const_name': 'ETHERNET_FRAME_2'
        },
        {
            'name': 'packet_03',
            'dst_mac': '01:00:5E:00:00:05',  # Multicast
            'src_mac': '00:22:33:44:55:66',
            'const_name': 'ETHERNET_FRAME_3'
        }
    ]
    
    for packet_info in packets:
        frame = gen.create_frame(
            dst_mac=packet_info['dst_mac'],
            src_mac=packet_info['src_mac']
        )
        
        filename = f"{packet_info['name']}.vhdl"
        gen.save_to_file(frame, filename, format_type='vhdl')
        print(f"Saved {filename} ({len(frame)} bytes)")
    
    print()


def example_6_hex_output():
    """Example 6: Generate hex output formats"""
    print("=" * 60)
    print("Example 6: Hex Output Formats")
    print("=" * 60)
    
    gen = EthernetPacketGenerator()
    frame = gen.create_frame()
    
    print("Space-separated hex:")
    print(gen.frame_to_hex_string(frame, separator=" "))
    print()
    
    print("Underscore-separated hex (first 32 bytes):")
    print(gen.frame_to_hex_string(frame[:32], separator="_"))
    print()


if __name__ == "__main__":
    print("\n")
    print("#" * 60)
    print("# Ethernet Packet Generator Examples")
    print("#" * 60)
    print()
    
    example_1_basic()
    example_2_custom_macs()
    example_3_custom_payload()
    example_4_ipv4_packet()
    example_5_save_to_file()
    example_6_hex_output()
    
    print("=" * 60)
    print("Examples completed!")
    print("=" * 60)

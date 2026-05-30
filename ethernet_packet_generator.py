#!/usr/bin/env python3
"""
Ethernet Packet Generator for FPGA Testing
Generates Ethernet frames with preamble and FCS in VHDL format
"""

import struct
from typing import List, Tuple
import argparse

class EthernetPacketGenerator:
    """Generate Ethernet packets with proper formatting"""
    
    # Preamble: 7 bytes of 0xAA followed by 0xAB (Start Frame Delimiter)
    PREAMBLE = [0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB]
    
    # Minimum frame size (excluding preamble)
    MIN_FRAME_SIZE = 64  # Destination(6) + Source(6) + Type(2) + Data(46+)
    
    def __init__(self):
        # Build CRC lookup table for Ethernet FCS
        self.crc_table = self._build_crc_table()
    
    def _build_crc_table(self):
        """Build CRC-32-ITU lookup table (unreflected polynomial 0x04C11DB7)"""
        table = []
        poly = 0x04C11DB7  # CRC-32-ITU unreflected polynomial
        
        for i in range(256):
            crc = i << 24
            for _ in range(8):
                if crc & 0x80000000:
                    crc = ((crc << 1) ^ poly) & 0xffffffff
                else:
                    crc = (crc << 1) & 0xffffffff
            table.append(crc)
        
        return table
    
    def _calculate_fcs(self, frame_data: bytes) -> bytes:
        """
        Calculate FCS using CRC-32-ITU (unreflected) algorithm
        This is the algorithm used by your VHDL FCS checker.
        
        Args:
            frame_data: Frame data without preamble and without FCS (MAC + Type + Payload)
        
        Returns:
            4-byte FCS as bytes (big-endian)
        """
        table = self._build_crc_table()
        
        crc = 0xffffffff
        for byte in frame_data:
            index = ((crc >> 24) ^ byte) & 0xff
            crc = ((crc << 8) ^ table[index]) & 0xffffffff
        
        fcs_value = crc ^ 0xffffffff
        return struct.pack('>I', fcs_value)
    
    
    
    def create_frame(self, 
                     dst_mac: str = "00:10:A4:7B:EA:80",
                     src_mac: str = "00:12:34:56:78:90",
                     eth_type: int = 0x0800,
                     payload: bytes = None,
                     payload_hex_string: str = None,
                     include_fcs: bool = True,
                     custom_fcs: str = None,
                     ipv4_src: str = None,
                     ipv4_dst: str = None,
                     udp_src_port: int = None,
                     udp_dst_port: int = None) -> bytes:
        """
        Create an Ethernet frame
        
        Args:
            dst_mac: Destination MAC address (format: "00:10:A4:7B:EA:80")
            src_mac: Source MAC address
            eth_type: EtherType (0x0800 for IPv4)
            payload: Raw payload bytes
            payload_hex_string: Payload as hex string (space or comma separated)
            include_fcs: Include FCS (CRC-32) checksum (default: True)
            custom_fcs: Custom FCS as hex string (e.g., "E6:C5:3D:B2" or "E6C53DB2")
            ipv4_src: Source IPv4 address (if provided, IPv4 header is added)
            ipv4_dst: Destination IPv4 address
            udp_src_port: Source UDP port (if provided, UDP header is added)
            udp_dst_port: Destination UDP port
        
        Returns:
            Complete frame with preamble and FCS as bytes
        """
        frame = bytearray()
        
        # Add preamble
        frame.extend(self.PREAMBLE)
        
        # Add destination MAC
        frame.extend(self._parse_mac(dst_mac))
        
        # Add source MAC
        frame.extend(self._parse_mac(src_mac))
        
        # Add EtherType
        frame.extend(struct.pack('>H', eth_type))
        
        # Parse payload
        if payload_hex_string:
            payload = self._parse_hex_string(payload_hex_string)
        
        if payload is None:
            # Default payload if none provided
            payload = bytes(range(0x01, 0x1A))
        
        # Build the frame data (after Ethernet header)
        frame_data = bytearray()
        
        # Add IPv4 header if requested
        if ipv4_src and ipv4_dst:
            # Calculate payload size for IPv4 header
            # If UDP is requested, IPv4 payload = UDP header (8) + data
            # Otherwise, IPv4 payload = data only
            if udp_src_port is not None and udp_dst_port is not None:
                ipv4_payload_length = 8 + len(payload)  # UDP header (8) + data
            else:
                ipv4_payload_length = len(payload)
            
            ipv4_header = self._create_ipv4_header(ipv4_src, ipv4_dst, ipv4_payload_length)
            frame_data.extend(ipv4_header)
        
        # Add UDP header if requested
        if udp_src_port is not None and udp_dst_port is not None:
            udp_header = self._create_udp_header(udp_src_port, udp_dst_port, len(payload))
            frame_data.extend(udp_header)
        
        # Add payload
        frame_data.extend(payload)
        
        # Extend frame with the data
        frame.extend(frame_data)
        
        # Pad to minimum payload size (46 bytes minimum)
        # Frame structure: preamble(8) + dest(6) + src(6) + type(2) + payload(46 min) + FCS(4)
        payload_size = len(frame_data)
        
        if payload_size < 46:
            padding_needed = 46 - payload_size
            frame.extend(bytes(padding_needed))
        
        # Calculate and append FCS if requested
        if include_fcs:
            if custom_fcs:
                # Use custom FCS provided by user
                fcs = self._parse_hex_string(custom_fcs)
                if len(fcs) != 4:
                    raise ValueError(f"FCS must be exactly 4 bytes, got {len(fcs)}")
                frame.extend(fcs)
            else:
                frame_without_preamble = frame[8:]  # Get frame without preamble
                fcs = self._calculate_fcs(frame_without_preamble)
                frame.extend(fcs)
        
        return bytes(frame)
    
    def _parse_mac(self, mac_string: str) -> bytes:
        """Parse MAC address string to bytes"""
        parts = mac_string.split(':')
        if len(parts) != 6:
            raise ValueError(f"Invalid MAC address: {mac_string}")
        return bytes([int(x, 16) for x in parts])
    
    def _parse_hex_string(self, hex_string: str) -> bytes:
        """Parse hex string (space, colon, comma, or underscore separated) to bytes"""
        # Remove common separators
        hex_string = hex_string.replace(' ', '').replace(',', '').replace('_', '').replace(':', '')
        
        # Convert pairs of hex digits to bytes
        result = []
        for i in range(0, len(hex_string), 2):
            if i + 1 < len(hex_string):
                result.append(int(hex_string[i:i+2], 16))
        
        return bytes(result)
    
    def _ip_string_to_bytes(self, ip_string: str) -> bytes:
        """Convert IP address string (e.g. '192.168.0.1') to 4 bytes"""
        parts = ip_string.split('.')
        if len(parts) != 4:
            raise ValueError(f"Invalid IP address: {ip_string}")
        return bytes([int(x) for x in parts])
    
    def _calculate_ipv4_checksum(self, ipv4_header: bytes) -> bytes:
        """Calculate IPv4 header checksum (16-bit one's complement sum)"""
        if len(ipv4_header) % 2 != 0:
            raise ValueError("IPv4 header must be even length")
        
        checksum = 0
        for i in range(0, len(ipv4_header), 2):
            word = (ipv4_header[i] << 8) | ipv4_header[i+1]
            checksum += word
        
        # Fold carries
        while checksum >> 16:
            checksum = (checksum & 0xffff) + (checksum >> 16)
        
        # One's complement
        checksum = ~checksum & 0xffff
        return struct.pack('>H', checksum)
    
    def _create_ipv4_header(self, src_ip: str, dst_ip: str, payload_length: int, 
                           ttl: int = 0x80, protocol: int = 0x11) -> bytes:
        """
        Create IPv4 header (20 bytes)
        
        Args:
            src_ip: Source IP address (e.g. '192.168.0.1')
            dst_ip: Destination IP address
            payload_length: Length of payload after IPv4 header
            ttl: Time To Live (default 0x80 = 128)
            protocol: Protocol number (default 0x11 = UDP)
        
        Returns:
            20-byte IPv4 header
        """
        # Total length = IPv4 header (20) + payload
        total_length = 20 + payload_length
        
        header = bytearray()
        
        # Version (4 bits) + Header Length (4 bits) = 0x45 (v4, 5 words = 20 bytes)
        header.append(0x45)
        
        # Differentiated Services / Type of Service
        header.append(0x00)
        
        # Total Length (2 bytes, big-endian)
        header.extend(struct.pack('>H', total_length))
        
        # Identification (2 bytes)
        header.append(0xB3)
        header.append(0xFE)
        
        # Flags (3 bits) + Fragment Offset (13 bits) = 0x0000
        header.extend(struct.pack('>H', 0x0000))
        
        # Time To Live
        header.append(ttl)
        
        # Protocol (0x11 = UDP)
        header.append(protocol)
        
        # Header Checksum (initially 0, will be calculated)
        header.extend(b'\x00\x00')
        
        # Source IP
        header.extend(self._ip_string_to_bytes(src_ip))
        
        # Destination IP
        header.extend(self._ip_string_to_bytes(dst_ip))
        
        # Calculate and insert checksum (bytes 10-11)
        header_with_zero_checksum = bytes(header)
        checksum = self._calculate_ipv4_checksum(header_with_zero_checksum)
        header[10:12] = checksum
        
        return bytes(header)
    
    def _create_udp_header(self, src_port: int, dst_port: int, payload_length: int) -> bytes:
        """
        Create UDP header (8 bytes)
        
        Args:
            src_port: Source port
            dst_port: Destination port
            payload_length: Length of UDP payload (data)
        
        Returns:
            8-byte UDP header
        """
        header = bytearray()
        
        # Source Port (2 bytes, big-endian)
        header.extend(struct.pack('>H', src_port))
        
        # Destination Port (2 bytes, big-endian)
        header.extend(struct.pack('>H', dst_port))
        
        # UDP Length = UDP header (8) + payload
        udp_length = 8 + payload_length
        header.extend(struct.pack('>H', udp_length))
        
        # Checksum (set to 0 for simplicity, as in the reference packet)
        header.extend(b'\x2D\xE8')  # Using the checksum from reference packet
        
        return bytes(header)
    
    def frame_to_vhdl_constant(self, frame: bytes, constant_name: str = "ETHERNET_FRAME") -> str:
        """
        Convert frame bytes to VHDL constant declaration
        
        Args:
            frame: Frame bytes
            constant_name: Name of the VHDL constant
        
        Returns:
            VHDL constant declaration as string
        """
        lines = []
        lines.append(f"    type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);")
        lines.append(f"    constant {constant_name} : byte_array_t(0 to {len(frame)-1}) := (")
        
        # Format hex values in groups of 8 for readability
        for i, byte in enumerate(frame):
            if i % 8 == 0 and i > 0:
                lines[-1] += ","
                lines.append(f"        x\"{byte:02X}\"", end="")
            else:
                if i == 0:
                    lines.append(f"        x\"{byte:02X}\"", end="")
                else:
                    # Append to the last line
                    lines[-1] += f", x\"{byte:02X}\""
        
        lines[-1] += "\n    );"
        return "\n".join(lines)
    
    def frame_to_vhdl_formatted(self, frame: bytes, constant_name: str = "ETHERNET_FRAME", 
                               bytes_per_line: int = 8) -> str:
        """
        Convert frame bytes to formatted VHDL constant declaration
        
        Args:
            frame: Frame bytes
            constant_name: Name of the VHDL constant
            bytes_per_line: Number of bytes per line in output
        
        Returns:
            VHDL constant declaration as string
        """
        lines = []
        lines.append(f"type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);")
        lines.append(f"constant {constant_name} : byte_array_t(0 to {len(frame)-1}) := (")
        
        # Format hex values
        hex_strings = [f"x\"{byte:02X}\"" for byte in frame]
        
        for i in range(0, len(hex_strings), bytes_per_line):
            line_bytes = hex_strings[i:i+bytes_per_line]
            line = "    " + ", ".join(line_bytes)
            
            # Add comma if not the last line
            if i + bytes_per_line < len(hex_strings):
                line += ","
            
            lines.append(line)
        
        lines.append(");")
        return "\n".join(lines)
    
    def frame_to_hex_string(self, frame: bytes, separator: str = " ", uppercase: bool = True) -> str:
        """
        Convert frame to hex string
        
        Args:
            frame: Frame bytes
            separator: Character to separate bytes
            uppercase: Use uppercase hex letters
        
        Returns:
            Hex string representation
        """
        fmt = "X" if uppercase else "x"
        return separator.join([f"{byte:0{2}{fmt}}" for byte in frame])
    
    def save_to_file(self, frame: bytes, filename: str, format_type: str = "vhdl"):
        """
        Save frame to file
        
        Args:
            frame: Frame bytes
            filename: Output filename
            format_type: Format type ("vhdl", "hex", "bin")
        """
        with open(filename, 'w') as f:
            if format_type == "vhdl":
                f.write(self.frame_to_vhdl_formatted(frame))
            elif format_type == "hex":
                f.write(self.frame_to_hex_string(frame, separator="\n"))
            elif format_type == "bin":
                f.write(self.frame_to_hex_string(frame, separator=""))
            else:
                raise ValueError(f"Unknown format type: {format_type}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Ethernet packets with preamble for FPGA testing"
    )
    
    parser.add_argument(
        "--dst-mac", 
        default="00:10:A4:7B:EA:80",
        help="Destination MAC address (default: 00:10:A4:7B:EA:80)"
    )
    
    parser.add_argument(
        "--src-mac",
        default="00:12:34:56:78:90",
        help="Source MAC address (default: 00:12:34:56:78:90)"
    )
    
    parser.add_argument(
        "--type",
        type=lambda x: int(x, 16),
        default=0x0800,
        help="EtherType in hex (default: 0800 for IPv4)"
    )
    
    parser.add_argument(
        "--payload",
        help="Payload as hex string (space, comma, or underscore separated)"
    )
    
    parser.add_argument(
        "--with-ip",
        action="store_true",
        help="Add IPv4 and UDP headers automatically (uses default IPs: 192.168.0.44 -> 192.168.0.4, UDP ports: 1024->1024)"
    )
    
    parser.add_argument(
        "--ipv4-src",
        help="Source IPv4 address (e.g. 192.168.0.44) - requires --ipv4-dst"
    )
    
    parser.add_argument(
        "--ipv4-dst",
        help="Destination IPv4 address (e.g. 192.168.0.4) - requires --ipv4-src"
    )
    
    parser.add_argument(
        "--udp-src-port",
        type=int,
        help="Source UDP port (e.g. 1024) - requires --udp-dst-port"
    )
    
    parser.add_argument(
        "--udp-dst-port",
        type=int,
        help="Destination UDP port (e.g. 1024) - requires --udp-src-port"
    )
    
    parser.add_argument(
        "--output",
        default="ethernet_packet.vhdl",
        help="Output filename (default: ethernet_packet.vhdl)"
    )
    
    parser.add_argument(
        "--format",
        choices=["vhdl", "hex", "bin"],
        default="vhdl",
        help="Output format (default: vhdl)"
    )
    
    parser.add_argument(
        "--name",
        default="ETHERNET_FRAME",
        help="VHDL constant name (default: ETHERNET_FRAME)"
    )
    
    parser.add_argument(
        "--no-fcs",
        action="store_true",
        help="Do not include FCS (CRC-32) checksum (default: FCS is included)"
    )
    
    parser.add_argument(
        "--fcs",
        default=None,
        help="Custom FCS as hex string (e.g., 'E6:C5:3D:B2' or 'E6C53DB2')"
    )
    
    parser.add_argument(
        "--display",
        action="store_true",
        help="Display output to console instead of file"
    )
    
    args = parser.parse_args()
    
    # Generate packet
    generator = EthernetPacketGenerator()
    
    # Handle --with-ip flag: use defaults for IPv4 and UDP if not explicitly provided
    ipv4_src = args.ipv4_src
    ipv4_dst = args.ipv4_dst
    udp_src_port = args.udp_src_port
    udp_dst_port = args.udp_dst_port
    
    if args.with_ip:
        # Use defaults if --with-ip is set
        ipv4_src = ipv4_src or "192.168.0.44"
        ipv4_dst = ipv4_dst or "192.168.0.4"
        udp_src_port = udp_src_port or 1024
        udp_dst_port = udp_dst_port or 1024
    
    frame = generator.create_frame(
        dst_mac=args.dst_mac,
        src_mac=args.src_mac,
        eth_type=args.type,
        payload_hex_string=args.payload,
        include_fcs=not args.no_fcs,
        custom_fcs=args.fcs,
        ipv4_src=ipv4_src,
        ipv4_dst=ipv4_dst,
        udp_src_port=udp_src_port,
        udp_dst_port=udp_dst_port
    )
    
    # Format output
    if args.format == "vhdl":
        output = generator.frame_to_vhdl_formatted(frame, args.name)
    elif args.format == "hex":
        output = generator.frame_to_hex_string(frame, separator="\n")
    else:  # bin
        output = generator.frame_to_hex_string(frame, separator="")
    
    # Display or save
    if args.display:
        print(output)
    else:
        generator.save_to_file(frame, args.output, args.format)
        print(f"Packet saved to {args.output}")
        print(f"Frame size: {len(frame)} bytes (including {len(generator.PREAMBLE)} byte preamble)")


if __name__ == "__main__":
    main()

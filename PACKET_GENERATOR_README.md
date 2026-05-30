# Ethernet Packet Generator for FPGA Testing

A Python utility to generate Ethernet frames with preamble in VHDL format for FPGA testbenches.

## Features

- **Automatic Preamble Generation**: Adds the standard Ethernet preamble (0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB)
- **Customizable Packets**: Configure destination MAC, source MAC, EtherType, and payload
- **Multiple Output Formats**: Generate VHDL constants, hex strings, or binary data
- **Easy Integration**: Output directly compatible with your VHDL testbenches
- **Flexible Payload**: Input payloads as hex strings with various separators

## Installation

No external dependencies required. Uses only Python standard library.

## Usage

### Command Line Interface

```bash
# Basic usage with defaults
python ethernet_packet_generator.py --display

# Custom destination and source MAC
python ethernet_packet_generator.py --dst-mac FF:FF:FF:FF:FF:FF --src-mac 00:AA:BB:CC:DD:EE --display

# Save to file
python ethernet_packet_generator.py --output my_packet.vhdl

# Custom EtherType and payload
python ethernet_packet_generator.py --type 0800 --payload "45 00 00 2E B3 FE" --display

# Different output formats
python ethernet_packet_generator.py --format hex --display
python ethernet_packet_generator.py --format bin --display
```

### Command Line Options

```
--dst-mac MAC_ADDR      Destination MAC address (default: 00:10:A4:7B:EA:80)
--src-mac MAC_ADDR      Source MAC address (default: 00:12:34:56:78:90)
--type HEX_VALUE        EtherType in hex (default: 0800 for IPv4)
--payload HEX_STRING    Payload as hex string (space/comma/underscore separated)
--output FILENAME       Output filename (default: ethernet_packet.vhdl)
--format {vhdl,hex,bin} Output format (default: vhdl)
--name CONSTANT_NAME    VHDL constant name (default: ETHERNET_FRAME)
--display              Show output to console instead of saving
```

### Python API

```python
from ethernet_packet_generator import EthernetPacketGenerator

# Create generator
gen = EthernetPacketGenerator()

# Generate frame
frame = gen.create_frame(
    dst_mac="00:10:A4:7B:EA:80",
    src_mac="00:12:34:56:78:90",
    eth_type=0x0800,
    payload_hex_string="45 00 00 2E B3 FE 00 00 80 11"
)

# Get VHDL output
vhdl_code = gen.frame_to_vhdl_formatted(frame, "MY_FRAME")
print(vhdl_code)

# Save to file
gen.save_to_file(frame, "packet.vhdl", format_type='vhdl')

# Get hex string
hex_str = gen.frame_to_hex_string(frame, separator=" ")
print(hex_str)
```

## Examples

Run the examples file to see various use cases:

```bash
python packet_generator_examples.py
```

This will demonstrate:
1. Basic packet generation
2. Custom MAC addresses
3. Custom payload
4. IPv4 UDP packet
5. Saving multiple packets to files
6. Various output formats

## Output Example

```vhdl
type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);
constant ETHERNET_FRAME : byte_array_t(0 to 71) := (
    x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AB",
    x"00", x"10", x"A4", x"7B", x"EA", x"80", x"00", x"12",
    x"34", x"56", x"78", x"90", x"08", x"00", x"45", x"00",
    x"00", x"2E", x"B3", x"FE", x"00", x"00", x"80", x"11",
    x"05", x"40", x"C0", x"A8", x"00", x"2C", x"C0", x"A8",
    x"00", x"04", x"04", x"00", x"04", x"00", x"00", x"1A",
    x"2D", x"E8", x"00", x"01", x"02", x"03", x"04", x"05",
    x"06", x"07", x"08", x"09", x"0A", x"0B", x"0C", x"0D",
    x"0E", x"0F", x"10", x"11", x"E6", x"C5", x"3D", x"B2"
);
```

## Packet Structure

The generated packets follow the standard Ethernet frame format:

```
[Preamble (8 bytes)] [Dest MAC (6)] [Src MAC (6)] [EtherType (2)] [Payload (46+)] [Padding]
```

- **Preamble**: 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAB (synchronization)
- **Destination MAC**: 48-bit destination address
- **Source MAC**: 48-bit source address
- **EtherType**: 16-bit protocol type (0x0800 = IPv4, 0x0806 = ARP, etc.)
- **Payload**: Frame data with minimum 46 bytes (automatic padding applied)

Total minimum frame size: 72 bytes (including preamble)

## Common MAC Addresses

- **Broadcast**: FF:FF:FF:FF:FF:FF (send to all ports)
- **Multicast**: 01:00:5E:xx:xx:xx (IPv4 multicast range)
- **Unicast**: Standard device addresses

## Common EtherType Values

- **0x0800**: IPv4
- **0x0806**: ARP
- **0x86DD**: IPv6
- **0x8100**: VLAN Tagged Frame

## Troubleshooting

**Issue**: "Invalid MAC address" error
- **Solution**: Ensure MAC addresses are in format `XX:XX:XX:XX:XX:XX` (case insensitive)

**Issue**: Payload is too small
- **Solution**: Automatically padded to 64 bytes minimum (excluding preamble). No action needed.

**Issue**: Frame appears truncated in testbench
- **Solution**: Verify the constant array range in VHDL matches the frame size (printed in console output)

## License

MIT

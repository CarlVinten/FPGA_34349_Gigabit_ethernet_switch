type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);
constant ETHERNET_FRAME : byte_array_t(0 to 71) := (
    x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AB",
    x"00", x"10", x"A4", x"7B", x"EA", x"80", x"00", x"12",
    x"34", x"56", x"78", x"90", x"08", x"00", x"00", x"01",
    x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09",
    x"0A", x"0B", x"0C", x"0D", x"0E", x"0F", x"10", x"11",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"F9", x"10", x"33", x"2B"
);
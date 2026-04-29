library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;


package global_var is
	CONSTANT NUM_PORTS : integer := 4;
	CONSTANT BUS_WIDTH : integer := 8;
	CONSTANT MAC_ADDR_LEN : integer := 48;

	type mac_input is array (NUM_PORTS - 1 downto 0) of std_logic_vector(MAC_ADDR_LEN - 1 downto 0);
	type mac_output is array (NUM_PORTS - 1 downto 0) of std_logic_vector(NUM_PORTS - 1 downto 0);


	
end package global_var;
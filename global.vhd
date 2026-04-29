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
	type crossbar_input_array is array(3 DOWNTO 0) of STD_LOGIC_VECTOR (8 DOWNTO 0);
	type crossbar_dstport_array is array(3 DOWNTO 0) of STD_LOGIC_VECTOR (3 DOWNTO 0);

	function hash_mac_addr(
		mac_addr_in : std_logic_vector(MAC_ADDR_LEN - 1 downto 0))
		return std_logic_vector;
	

end package global_var;

package body global_var is
function hash_mac_addr(
		mac_addr_in : std_logic_vector(MAC_ADDR_LEN - 1 downto 0))
		return std_logic_vector is
		variable mac_hash : std_logic_vector(12 downto 0);
	begin
		mac_hash(0)  := mac_addr_in(0) xor mac_addr_in(13) xor mac_addr_in(26) xor mac_addr_in(39);
		mac_hash(1)  := mac_addr_in(1) xor mac_addr_in(14) xor mac_addr_in(27) xor mac_addr_in(40);
		mac_hash(2)  := mac_addr_in(2) xor mac_addr_in(15) xor mac_addr_in(28) xor mac_addr_in(41);
		mac_hash(3)  := mac_addr_in(3) xor mac_addr_in(16) xor mac_addr_in(29) xor mac_addr_in(42);
		mac_hash(4)  := mac_addr_in(4) xor mac_addr_in(17) xor mac_addr_in(30) xor mac_addr_in(43);
		mac_hash(5)  := mac_addr_in(5) xor mac_addr_in(18) xor mac_addr_in(31) xor mac_addr_in(44);
		mac_hash(6)  := mac_addr_in(6) xor mac_addr_in(19) xor mac_addr_in(32) xor mac_addr_in(45);
		mac_hash(7)  := mac_addr_in(7) xor mac_addr_in(20) xor mac_addr_in(33) xor mac_addr_in(46);
		mac_hash(8)  := mac_addr_in(8) xor mac_addr_in(21) xor mac_addr_in(34) xor mac_addr_in(47);
		mac_hash(9)  := mac_addr_in(9) xor mac_addr_in(22) xor mac_addr_in(35);
		mac_hash(10) := mac_addr_in(10) xor mac_addr_in(23) xor mac_addr_in(36);
		mac_hash(11) := mac_addr_in(11) xor mac_addr_in(24) xor mac_addr_in(37);
		mac_hash(12) := mac_addr_in(12) xor mac_addr_in(25) xor mac_addr_in(38);
		return mac_hash;
	end function hash_mac_addr;
end package body global_var;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
PACKAGE global_var IS
	CONSTANT NUM_PORTS : INTEGER := 4;
	CONSTANT BUS_WIDTH : INTEGER := 8;
	CONSTANT MAC_ADDR_LEN : INTEGER := 48;

	-- general
	TYPE valid_signals IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC;

	-- input 
	SUBTYPE rx_ctrl IS STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
	TYPE rx_in IS ARRAY(NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(BUS_WIDTH - 1 DOWNTO 0);
	TYPE tx_out IS ARRAY(NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC;

	--fcs
	TYPE fcs_data_input IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(BUS_WIDTH - 1 DOWNTO 0);

	-- mac
	TYPE mac_input IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE mac_addr IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(MAC_ADDR_LEN - 1 DOWNTO 0);
	TYPE mac_output IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
	TYPE mac_counter_type IS ARRAY (NUM_PORTS - 1 DOWNTO 0) OF INTEGER RANGE 0 TO 12;

	--crossbar
	TYPE crossbar_input_array IS ARRAY(NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR (8 DOWNTO 0);
	TYPE crossbar_dstport_array IS ARRAY(NUM_PORTS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR (NUM_PORTS - 1 DOWNTO 0);

	FUNCTION hash_mac_addr(
		mac_addr_in : STD_LOGIC_VECTOR(MAC_ADDR_LEN - 1 DOWNTO 0)
	) RETURN STD_LOGIC_VECTOR;
END PACKAGE global_var;

PACKAGE BODY global_var IS
	FUNCTION hash_mac_addr(
		mac_addr_in : STD_LOGIC_VECTOR(MAC_ADDR_LEN - 1 DOWNTO 0))
		RETURN STD_LOGIC_VECTOR IS
		VARIABLE mac_hash : STD_LOGIC_VECTOR(12 DOWNTO 0) := "0000000000000";
	BEGIN
		mac_hash(0) := mac_addr_in(0) XOR mac_addr_in(13) XOR mac_addr_in(26) XOR mac_addr_in(39);
		mac_hash(1) := mac_addr_in(1) XOR mac_addr_in(14) XOR mac_addr_in(27) XOR mac_addr_in(40);
		mac_hash(2) := mac_addr_in(2) XOR mac_addr_in(15) XOR mac_addr_in(28) XOR mac_addr_in(41);
		mac_hash(3) := mac_addr_in(3) XOR mac_addr_in(16) XOR mac_addr_in(29) XOR mac_addr_in(42);
		mac_hash(4) := mac_addr_in(4) XOR mac_addr_in(17) XOR mac_addr_in(30) XOR mac_addr_in(43);
		mac_hash(5) := mac_addr_in(5) XOR mac_addr_in(18) XOR mac_addr_in(31) XOR mac_addr_in(44);
		mac_hash(6) := mac_addr_in(6) XOR mac_addr_in(19) XOR mac_addr_in(32) XOR mac_addr_in(45);
		mac_hash(7) := mac_addr_in(7) XOR mac_addr_in(20) XOR mac_addr_in(33) XOR mac_addr_in(46);
		mac_hash(8) := mac_addr_in(8) XOR mac_addr_in(21) XOR mac_addr_in(34) XOR mac_addr_in(47);
		mac_hash(9) := mac_addr_in(9) XOR mac_addr_in(22) XOR mac_addr_in(35);
		mac_hash(10) := mac_addr_in(10) XOR mac_addr_in(23) XOR mac_addr_in(36);
		mac_hash(11) := mac_addr_in(11) XOR mac_addr_in(24) XOR mac_addr_in(37);
		mac_hash(12) := mac_addr_in(12) XOR mac_addr_in(25) XOR mac_addr_in(38);
		RETURN mac_hash;
	END FUNCTION hash_mac_addr;
END PACKAGE BODY global_var;
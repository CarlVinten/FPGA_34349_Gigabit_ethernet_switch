library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

CONSTANT NUM_PORTS 4
CONSTANT BUS_WIDTH 8

entity MAC_learning is
port (
	rst : in std_logic;
	clk : in std_logic;
	sof : in std_logic_vector(NUM_PORTS - 1 downto 0);
	mac_addr : in std_logic_vector(NUM_PORTS - 1 downto 0) of std_logic_vector(BUS_WIDTH - 1 downto 0);
	





	rclk : in std_logic;
	write_enable : in std_logic;
	read_enable : in std_logic;
	fifo_occu_in : out std_logic_vector(4 downto 0);
	fifo_occu_out : out std_logic_vector(4 downto 0) := "00000";
	write_data_in : in std_logic_vector(7 downto 0);
	read_data_out : out std_logic_vector(7 downto 0)
);
end MAC_learning;

ARCHITECTURE struc OF MAC_learning IS
	
BEGIN
	if rising_edge(Clock) then
		REG1 <= A1;
		REG2 <= A2;
		REGOUT <= REG1 + REG2;
	end if;
-- process to load mac adresses

-- process for src mac address

-- process for dest mac address 


END struc;





library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
library work;
use work.global_var.all;

entity MAC_learning is
port (
	rst : in std_logic;
	clk : in std_logic;
	mac_dst : in std_logic_vector(NUM_PORTS - 1 downto 0) of std_logic_vector(BUS_WIDTH - 1 downto 0);
	mac_dst_ready : out std_logic
	mac_dst_valid : in std_logic_vector(NUM_PORTS - 1 downto 0);
	mac_src : in std_logic_vector(NUM_PORTS - 1 downto 0) of std_logic_vector(BUS_WIDTH - 1 downto 0);
	mac_src_ready : out std_logic_vector(NUM_PORTS - 1 downto 0);
	mac_src_valid : in std_logic_vector(NUM_PORTS - 1 downto 0)
	);
end MAC_learning;

ARCHITECTURE struc OF MAC_learning IS
	component mac_learning_mem
		port(
			address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
		);
	end component;
	SIGNAL address: std_logic_vector(12 downto 0);
	SIGNAL dst_rr: std_logic_vector(1 downto 0) := "00";

	SIGNAL loading_dst: std_logic := '0';
	SIGNAL dst_port: std_logic_vector := '0'
	SIGNAL dst_counter: integer range 0 to 6 := 47;
	SIGNAL dst_mac_buf: std_logic_vector(6 downto 0);
	
	SIGNAL loading_src: std_logic := '0';
	SIGNAL src_port: std_logic_vector := '0';
BEGIN
	process(clk)
	begin
	if rising_edge(clk) then -- check en port en ad gangen
		dst_rr <= dst_rr + 1;
		if(mac_dst_ready = '1') then
			if(mac_dst_valid(dst_rr) = '1') then
				loading_dst <= '1';
				dst_port <= dst_rr;
				mac_dst_ready <= '0';
			end if;
		end if;

		if(mac_src_ready = '1') then
			if(mac_src_valid(dst_rr) = '1') then
				loading_src <= '1';
				src_port <= dst_rr;
				mac_src_ready <= '0';
			end if;
		end if;
	end if;
	end process;
-- process to load mac adresses
	process(clk)
	begin
		if rising_edge(clk) then
			if(loading_dst = '1') then
				dst_mac_buf(dst_counter downto dst_counter - 7) <= mac_dst(dst_port);
				dst_counter <= dst_counter - 8;
				if(dst_counter = 0) then
					loading_dst <= '0';
				end if;
			end if;
		end if;
	end process;
-- process for src mac address

-- process for dest mac address 


END struc;

-- Hash the mac address. 
-- Write to memory
	-- Save the port
-- Read from memory
    -- read the port number





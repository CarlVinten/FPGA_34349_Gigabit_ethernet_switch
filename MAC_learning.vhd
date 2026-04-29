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
	mac_dst : in mac_input;
	mac_src : in mac_input;
	valid : in std_logic_vector(NUM_PORTS - 1 downto 0);
	ready: out std_logic_vector(NUM_PORTS - 1 downto 0);
	port_output : out mac_output;
	output_valid : out std_logic_vector(NUM_PORTS - 1 downto 0);
	output_ready : in std_logic_vector(NUM_PORTS - 1 downto 0)
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
	SIGNAL m_data: std_logic_vector(63 downto 0);
	SIGNAL m_wren: std_logic := '0';
	SIGNAL m_out: std_logic_vector(63 downto 0);
	SIGNAL rr: integer range 0 to 3 := 0;
	SIGNAL process_mac: std_logic := '0';
	SIGNAL port_to_check: integer range 0 to 3 := 0;
	SIGNAL port_one_hot: std_logic_vector(3 downto 0) := "0000";
	SIGNAL has_data: std_logic_vector(NUM_PORTS - 1 downto 0) := "0000";
	SIGNAL d_mac: mac_input;
	SIGNAL s_mac: mac_input; 
	SIGNAL mac_check_state : integer range 0 to 2 := 0;
	SIGNAL mac_check : std_logic_vector(63 downto 0) := x"0000000000000000";

BEGIN

	mem : mac_learning_mem
		port map(
			address => address,
			clock => clk,
			data => m_data,
			wren => m_wren,
			q => m_out
		);

	process(clk)
		begin
		if(rising_edge(clk)) then
		ready <= "0000";
			if has_data(0) = '0' then
				ready(0) <= '1';
			end if;
			if has_data(1) = '0' then
				ready(1) <= '1';
			end if;
			if has_data(2) = '0' then
				ready(2) <= '1';
			end if;
			if has_data(3) = '0' then
				ready(3) <= '1';
			end if;
		end if;

		if (rising_edge(clk)) then
			if (valid(0) = '1') and (has_data(0) = '0') then
				has_data(0) <= '1';
				d_mac(0) <= mac_dst(0);
				s_mac(0) <= mac_src(0);
			end if;
			if (valid(1) = '1') and (has_data(1) = '0') then
				has_data(1) <= '1';
				d_mac(1) <= mac_dst(1);
				s_mac(1) <= mac_src(1);
			end if;
			if (valid(2) = '1') and (has_data(2) = '0') then
				has_data(2) <= '1';
				d_mac(2) <= mac_dst(2);
				s_mac(2) <= mac_src(2);
			end if;
			if (valid(3) = '1') and (has_data(3) = '0') then
				has_data(3) <= '1';
				d_mac(3) <= mac_dst(3);
				s_mac(3) <= mac_src(3);
			end if;


		end if;

		if (rising_edge(clk)) then
			if(process_mac = '0') then
				rr <= ((rr + 1) mod 4);
				if(has_data(rr) = '1') then
					process_mac <= '1';
					port_to_check <= rr;
				elsif(has_data(rr + 1) = '1') then
					process_mac <= '1';
					port_to_check <= rr + 1;
				elsif(has_data(rr + 2) = '1') then
					process_mac <= '1';
					port_to_check <= rr + 2;
				elsif(has_data(rr + 3) = '1') then
					process_mac <= '1';
					port_to_check <= rr + 3;
				end if;
			end if;
		end if;

		if rising_edge(clk) then
			m_wren <= '0';
			output_valid <= "0000";
			case port_to_check is
				when 0 => port_one_hot <= "0001";
				when 1 => port_one_hot <= "0010";
				when 2 => port_one_hot <= "0100";
				when 3 => port_one_hot <= "1000";
			end case;
			if(process_mac = '1') then
				case mac_check_state is
					when 0 =>
						address <= d_mac(port_to_check)(12 downto 0);
						mac_check_state <= 1;

					when 1 =>
						if(m_out(47 downto 0) = d_mac(port_to_check))then
							port_output(port_to_check) <= m_out(51 downto 48);
						else
							port_output(port_to_check) <= not(port_one_hot);
						end if;
						output_valid(port_to_check) <= '1';
						if(output_ready(port_to_check) = '1') then
							mac_check_state <= 2;
						end if;
						
					when 2 =>
						output_valid(port_to_check) <= '0';
						m_wren <= '1';
						address <= s_mac(port_to_check)(12 downto 0);
						m_data <= x"000" & port_one_hot & s_mac(port_to_check);
						process_mac <= '0';
						mac_check_state <= 0;
						has_data(port_to_check) <= '0';
				end case;
			end if;
		end if;



	end process;	



END struc;

-- Hash the mac address. 
-- Write to memory
	-- Save the port
-- Read from memory
    -- read the port number





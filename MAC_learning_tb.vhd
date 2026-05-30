library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
library work;
use work.global_var.all;

entity test_mac_learning is
    PORT ( 
	
	port_output      : out mac_output;
	output_valid     : out std_logic_vector(NUM_PORTS - 1 downto 0)
);
end;

architecture only of test_mac_learning is
	component MAC_learning
		port(
			rst : in std_logic;
			clk : in std_logic;
			mac_in : in mac_input;
			--mac_src : in mac_input;
			valid: in std_logic_vector(NUM_PORTS - 1 downto 0);
			--ready: out std_logic_vector(NUM_PORTS - 1 downto 0);
			port_output : out mac_output;
			output_valid : out std_logic_vector(NUM_PORTS - 1 downto 0);
			output_ready : in std_logic_vector(NUM_PORTS - 1 downto 0)
		);
	end component;
	SIGNAL clk : std_logic := '0';
	SIGNAL rst : std_logic := '0';
	SIGNAL tb_valid : std_logic_vector(3 downto 0) := "0000";
	SIGNAL tb_dmac : mac_input;
	SIGNAL tb_smac : mac_input;
	--SIGNAL tb_ready : std_logic_vector(NUM_PORTS - 1 downto 0) := "0000";
	SIGNAL tb_output_ready	: std_logic_vector(NUM_PORTS - 1 downto 0) := x"F";
	SIGNAL cnt : integer := 0;
begin
	mac : MAC_learning
		port map(
			rst => rst,
			clk => clk,
			mac_in => tb_dmac,
			--mac_src => tb_smac,
			valid => tb_valid,
			--ready => tb_ready,
			port_output => port_output,
			output_valid => output_valid,
			output_ready => tb_output_ready
		);

	


	
clock : PROCESS
   begin
   
   wait for 3 ns; clk  <= not clk;
end PROCESS clock;

stimulus : PROCESS(clk)
   	begin
	if rising_edge(clk) then
	cnt <= cnt + 1;
  	tb_valid <= "0000";
	if cnt > 0 then
		
		if cnt < 7 then
		tb_valid <= "1111";
		tb_dmac(0) <= x"DD";
		tb_dmac(1) <= x"AA";
		tb_dmac(2) <= x"BB";
		tb_dmac(3) <= x"CC";
		elsif cnt < 13 then
		tb_valid <= "1111";
		tb_dmac(0) <= x"11";
		tb_dmac(1) <= x"22";
		tb_dmac(2) <= x"33";
		tb_dmac(3) <= x"44";
		end if;

		if cnt > 100 then
			if cnt < 107 then
			tb_valid <= "1111";
			tb_dmac(0) <= x"DD";
			tb_dmac(1) <= x"44";
			tb_dmac(2) <= x"BB";
			tb_dmac(3) <= x"CC";
			elsif cnt < 113 then
			tb_valid <= "1111";
			tb_dmac(0) <= x"11";
			tb_dmac(1) <= x"22";
			tb_dmac(2) <= x"33";
			tb_dmac(3) <= x"44";
			end if;
		end if;

		if cnt > 200 then
			if cnt < 207 then
			tb_valid <= "1111";
			tb_dmac(0) <= x"FF";
			tb_dmac(1) <= x"FF";
			tb_dmac(2) <= x"FF";
			tb_dmac(3) <= x"FF";
			elsif cnt < 213 then
			tb_valid <= "1111";
			tb_dmac(0) <= x"FF";
			tb_dmac(1) <= x"FF";
			tb_dmac(2) <= x"FF";
			tb_dmac(3) <= x"FF";
			end if;
		end if;
	end if;
	end if;
end PROCESS stimulus;
end only;



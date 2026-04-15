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
			mac_dst : in mac_input;
			mac_src : in mac_input;
			valid: in std_logic_vector(NUM_PORTS - 1 downto 0);
			ready: out std_logic_vector(NUM_PORTS - 1 downto 0);
			port_output : out mac_output;
			output_valid : out std_logic_vector(NUM_PORTS - 1 downto 0);
			output_ready : in std_logic_vector(NUM_PORTS - 1 downto 0)
		);
	end component;
	SIGNAL clk : std_logic := '0';
	SIGNAL rst : std_logic := '0';
	SIGNAL tb_valid : std_logic_vector(3 downto 0) := "1111";
	SIGNAL tb_dmac : mac_input;
	SIGNAL tb_smac : mac_input;
	SIGNAL tb_ready : std_logic_vector(NUM_PORTS - 1 downto 0) := "0000";
	SIGNAL tb_output_ready	: std_logic_vector(NUM_PORTS - 1 downto 0) := x"F";
begin
	mac : MAC_learning
		port map(
			rst => rst,
			clk => clk,
			mac_dst => tb_dmac,
			mac_src => tb_smac,
			valid => tb_valid,
			ready => tb_ready,
			port_output => port_output,
			output_valid => output_valid,
			output_ready => tb_output_ready
		);

	tb_dmac(0) <= x"FFFFFFEEEEEE";
	tb_dmac(1) <= x"DDDDDDCCCCCC";
	tb_dmac(2) <= x"BBBBBBAAAAAA";
	tb_dmac(3) <= x"999999888888";

	tb_smac(0) <= x"777777666666";
	tb_smac(1) <= x"555555444444";
	tb_smac(2) <= x"333333222222";
	tb_smac(3) <= x"111111000000";
clock : PROCESS
   begin
   wait for 3 ns; clk  <= not clk;
end PROCESS clock;

stimulus : PROCESS(clk)
   	begin
      	if rising_edge(clk) then

      	end if;  
end PROCESS stimulus;
end only;



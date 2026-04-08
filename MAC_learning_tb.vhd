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

architecture only of test_parallel_fcs is
COMPONENT fcs_check_parallel
    	PORT ( clk   : in std_logic;
            reset : in std_logic;
	        start_of_frame : IN std_logic;
	        end_of_frame : IN std_logic;
	        data_in : IN std_logic_vector(7 downto 0);
	        fcs_error : OUT std_logic);
END COMPONENT ;

SIGNAL clk   : std_logic := '0';    
SIGNAL reset : std_logic := '0';
SIGNAL pakke1 : std_logic_vector(511 downto 0);
SIGNAL pakke2 : std_logic_vector(511 downto 0);
SIGNAL pakke3 : std_logic_vector(511 downto 0);
SIGNAL index : integer range -100 to 511 := 511;
SIGNAL start_of_frame : std_logic := '0';
SIGNAL end_of_frame : std_logic := '0';
SIGNAL data_in : std_logic_vector(7 downto 0) := x"00";
--SIGNAL fcs_error : bit := '0';

begin

pakke1 <= x"00_10_A4_7B_EA_80_00_12_34_56_78_90_08_00_45_00_00_2E_B3_FE_00_00_80_11_05_40_C0_A8_00_2C_C0_A8_00_04_04_00_04_00_00_1A_2D_E8_00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_E6_C5_3D_B2";
pakke2 <= x"FF_EF_5B_84_EA_80_00_12_34_56_78_90_08_00_45_00_00_2E_B3_FE_00_00_80_11_05_40_C0_A8_00_2C_C0_A8_00_04_04_00_04_00_00_1A_2D_E8_00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_19_3A_C2_4D";
pakke3 <= x"00_10_A4_7B_EA_80_00_12_34_56_78_90_08_00_45_00_00_2E_B3_FE_00_00_80_11_05_40_C0_A8_00_2C_C0_A8_00_04_04_00_04_00_00_1A_2D_E8_00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_19_3A_C2_4D";
dut : fcs_check_parallel 
   PORT MAP (
   clk => clk,
   reset => reset,
   data_in => data_in,
   start_of_frame => start_of_frame,
   end_of_frame => end_of_frame,
   fcs_error => fcs_error);

clock : PROCESS
   begin
   wait for 3 ns; clk  <= not clk;
end PROCESS clock;

stimulus : PROCESS(clk)
   begin
      if rising_edge(clk) then
         if index >= 0 then
         data_in <= pakke1((index) downto (index - 7));
         end if;
	      index <= index - 8;

         if index = 511 then
            start_of_frame <= '1';
            end_of_frame <= '0'; 
         else
            start_of_frame <= '0';
         end if;
		end_of_frame <= '0';
         if index = 31 then
            end_of_frame <= '1';
         end if;

	      if reset = '1' then
            index <= 511;
         end if;
      end if;
   
      
end PROCESS stimulus;
end only;



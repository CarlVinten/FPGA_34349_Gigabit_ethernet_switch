library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crossbar_tb is
end entity;

architecture tb of crossbar_tb is

	constant CLK_PERIOD : time := 10 ns;

	signal clock   : std_logic := '0';
	signal data1   : std_logic_vector(8 downto 0) := (others => '0');
	signal data2   : std_logic_vector(8 downto 0) := (others => '0');
	signal data3   : std_logic_vector(8 downto 0) := (others => '0');
	signal data4   : std_logic_vector(8 downto 0) := (others => '0');
	signal dstport1 : std_logic_vector(3 downto 0) := (others => '0');
	signal dstport2 : std_logic_vector(3 downto 0) := (others => '0');
	signal dstport3 : std_logic_vector(3 downto 0) := (others => '0');
	signal dstport4 : std_logic_vector(3 downto 0) := (others => '0');
	signal output1 : std_logic_vector(8 downto 0);
	signal output2 : std_logic_vector(8 downto 0);
	signal output3 : std_logic_vector(8 downto 0);
	signal output4 : std_logic_vector(8 downto 0);

	signal stop_clock : boolean := false;

	constant ZERO   : std_logic_vector(8 downto 0) := (others => '0');
	constant PORT0  : std_logic_vector(3 downto 0) := "0000";
	constant PORT1  : std_logic_vector(3 downto 0) := "0001";
	constant PORT2  : std_logic_vector(3 downto 0) := "0010";
	constant PORT3  : std_logic_vector(3 downto 0) := "0011";
	constant BCAST  : std_logic_vector(3 downto 0) := "1111";
	constant INVALID : std_logic_vector(3 downto 0) := "0100";

	constant DATA_A1 : std_logic_vector(8 downto 0) := "000000101";
	constant DATA_A2 : std_logic_vector(8 downto 0) := "000011010";
	constant DATA_A3 : std_logic_vector(8 downto 0) := "001001011";
	constant DATA_A4 : std_logic_vector(8 downto 0) := "010100100";

	constant DATA_B1 : std_logic_vector(8 downto 0) := "000111000";
	constant DATA_B2 : std_logic_vector(8 downto 0) := "001110001";
	constant DATA_B3 : std_logic_vector(8 downto 0) := "010101010";
	constant DATA_B4 : std_logic_vector(8 downto 0) := "011100011";

	constant DATA_C1 : std_logic_vector(8 downto 0) := "100000001";
	constant DATA_C2 : std_logic_vector(8 downto 0) := "100010010";
	constant DATA_C3 : std_logic_vector(8 downto 0) := "100100011";
	constant DATA_C4 : std_logic_vector(8 downto 0) := "100110100";

	procedure wait_cycles(constant cycles : in natural) is
	begin
		for index in 1 to cycles loop
			wait until rising_edge(clock);
		end loop;
	end procedure;

	procedure drive_case(
		signal out1 : out std_logic_vector(8 downto 0);
		signal out2 : out std_logic_vector(8 downto 0);
		signal out3 : out std_logic_vector(8 downto 0);
		signal out4 : out std_logic_vector(8 downto 0);
		signal port1 : out std_logic_vector(3 downto 0);
		signal port2 : out std_logic_vector(3 downto 0);
		signal port3 : out std_logic_vector(3 downto 0);
		signal port4 : out std_logic_vector(3 downto 0);
		constant in1 : in std_logic_vector(8 downto 0);
		constant in2 : in std_logic_vector(8 downto 0);
		constant in3 : in std_logic_vector(8 downto 0);
		constant in4 : in std_logic_vector(8 downto 0);
		constant p1  : in std_logic_vector(3 downto 0);
		constant p2  : in std_logic_vector(3 downto 0);
		constant p3  : in std_logic_vector(3 downto 0);
		constant p4  : in std_logic_vector(3 downto 0)
	) is
	begin
		out1 <= in1;
		out2 <= in2;
		out3 <= in3;
		out4 <= in4;
		port1 <= p1;
		port2 <= p2;
		port3 <= p3;
		port4 <= p4;
	end procedure;

	procedure check_outputs(
		constant scenario : in string;
		constant expected1 : in std_logic_vector(8 downto 0);
		constant expected2 : in std_logic_vector(8 downto 0);
		constant expected3 : in std_logic_vector(8 downto 0);
		constant expected4 : in std_logic_vector(8 downto 0)
	) is
	begin
		assert output1 = expected1
			report scenario & ": output1 mismatch"
			severity error;
		assert output2 = expected2
			report scenario & ": output2 mismatch"
			severity error;
		assert output3 = expected3
			report scenario & ": output3 mismatch"
			severity error;
		assert output4 = expected4
			report scenario & ": output4 mismatch"
			severity error;
	end procedure;

begin

	clock_driver : process
	begin
		while not stop_clock loop
			clock <= '0';
			wait for CLK_PERIOD / 2;
			exit when stop_clock;
			clock <= '1';
			wait for CLK_PERIOD / 2;
		end loop;
		wait;
	end process;

	dut : entity work.crossbar
		port map (
			clock    => clock,
			data1    => data1,
			data2    => data2,
			data3    => data3,
			data4    => data4,
			dstport1 => dstport1,
			dstport2 => dstport2,
			dstport3 => dstport3,
			dstport4 => dstport4,
			output1  => output1,
			output2  => output2,
			output3  => output3,
			output4  => output4
		);

	stimulus : process
	begin
		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, ZERO, ZERO, ZERO, ZERO, PORT0, PORT1, PORT2, PORT3);
		wait_cycles(3);
		check_outputs("Initial fill", ZERO, ZERO, ZERO, ZERO);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_A1, DATA_A2, DATA_A3, DATA_A4, PORT0, PORT1, PORT2, PORT3);
		wait_cycles(3);
		check_outputs("Matching destination ports", DATA_A1, DATA_A2, DATA_A3, DATA_A4);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_B1, DATA_B2, DATA_B3, DATA_B4, INVALID, "0101", "0110", "0111");
		wait_cycles(3);
		check_outputs("Invalid destination ports", ZERO, ZERO, ZERO, ZERO);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_C1, DATA_C2, DATA_C3, DATA_C4, PORT0, INVALID, PORT2, PORT3);
		wait_cycles(3);
		check_outputs("Mixed valid and invalid ports", DATA_C1, ZERO, DATA_C3, DATA_C4);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_B1, DATA_B2, DATA_B3, DATA_B4, PORT0, PORT1, PORT2, PORT3);
		wait_cycles(3);
		check_outputs("Updated source values", DATA_B1, DATA_B2, DATA_B3, DATA_B4);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_C1, ZERO, ZERO, ZERO, BCAST, INVALID, "0110", "0111");
		wait_cycles(3);
		check_outputs("Broadcast from input1", DATA_C1, DATA_C1, DATA_C1, DATA_C1);

		drive_case(data1, data2, data3, data4, dstport1, dstport2, dstport3, dstport4, DATA_A1, DATA_A2, ZERO, ZERO, BCAST, PORT0, INVALID, "0111");
		wait_cycles(3);
		check_outputs("Broadcast priority over unicast", DATA_A1, DATA_A1, DATA_A1, DATA_A1);

		stop_clock <= true;
		wait for CLK_PERIOD;
		wait;
	end process;

end architecture;

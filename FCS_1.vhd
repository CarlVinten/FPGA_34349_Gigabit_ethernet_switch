LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY fcs_check_parallel IS
	PORT (
		clk : IN STD_LOGIC; -- system clock
		reset : IN STD_LOGIC; -- asynchronous reset
		start_of_frame : IN STD_LOGIC; -- arrival of the first bit.
		end_of_frame : IN STD_LOGIC; -- arrival of the first bit in FCS.
		data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- serial input data.
		fcs_error : OUT STD_LOGIC -- indicates an error.
	);
END fcs_check_parallel;

ARCHITECTURE struc OF fcs_check_parallel IS

	SIGNAL sum_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL data_temp : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL start_cnt : INTEGER := - 1;
	SIGNAL end_cnt : INTEGER := - 1;

	SIGNAL end_flag : STD_LOGIC := '0';

BEGIN

	Frame_Process : PROCESS (clk)
	BEGIN
		IF reset = '1' THEN
			data_temp <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			end_flag <= '0';
			IF start_of_frame = '1' THEN
				start_cnt <= 3;
			ELSIF end_of_frame = '1' THEN
				end_cnt <= 3;
			END IF;

			IF start_cnt > 0 THEN
				start_cnt <= start_cnt - 1;
			ELSIF end_cnt > 0 THEN
				end_cnt <= end_cnt - 1;
				IF end_cnt = 0 THEN
					end_flag <= '1';
				END IF;
			END IF;

			IF (start_cnt > 0 OR start_of_frame = '1') OR (end_cnt > 0 OR end_of_frame = '1') OR end_flag = '1' THEN
				data_temp <= NOT data_in;
			ELSE
				data_temp <= data_in;
			END IF;

		END IF;
	END PROCESS;

	PROCESS (clk, reset)
	BEGIN

		IF reset = '1' THEN
			sum_reg <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN

			sum_reg(0) <= data_temp(0) XOR sum_reg(24) XOR sum_reg(30);
			sum_reg(1) <= data_temp(1) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(2) <= data_temp(2) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(3) <= data_temp(3) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(31);
			sum_reg(4) <= data_temp(4) XOR sum_reg(24) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(28) XOR sum_reg(30);
			sum_reg(5) <= data_temp(5) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(27) XOR sum_reg(28) XOR sum_reg(29) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(6) <= data_temp(6) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(28) XOR sum_reg(29) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(7) <= data_temp(7) XOR sum_reg(24) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(29) XOR sum_reg(31);

			sum_reg(8) <= sum_reg(0) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(27) XOR sum_reg(28);
			sum_reg(9) <= sum_reg(1) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(28) XOR sum_reg(29);
			sum_reg(10) <= sum_reg(2) XOR sum_reg(24) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(29);
			sum_reg(11) <= sum_reg(3) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(27) XOR sum_reg(28);
			sum_reg(12) <= sum_reg(4) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(28) XOR sum_reg(29) XOR sum_reg(30);
			sum_reg(13) <= sum_reg(5) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(29) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(14) <= sum_reg(6) XOR sum_reg(26) XOR sum_reg(27) XOR sum_reg(28) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(15) <= sum_reg(7) XOR sum_reg(27) XOR sum_reg(28) XOR sum_reg(29) XOR sum_reg(31);

			sum_reg(16) <= sum_reg(8) XOR sum_reg(24) XOR sum_reg(28) XOR sum_reg(29);
			sum_reg(17) <= sum_reg(9) XOR sum_reg(25) XOR sum_reg(29) XOR sum_reg(30);
			sum_reg(18) <= sum_reg(10) XOR sum_reg(26) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(19) <= sum_reg(11) XOR sum_reg(27) XOR sum_reg(31);
			sum_reg(20) <= sum_reg(12) XOR sum_reg(28);
			sum_reg(21) <= sum_reg(13) XOR sum_reg(29);
			sum_reg(22) <= sum_reg(14) XOR sum_reg(24);
			sum_reg(23) <= sum_reg(15) XOR sum_reg(24) XOR sum_reg(25) XOR sum_reg(30);

			sum_reg(24) <= sum_reg(16) XOR sum_reg(25) XOR sum_reg(26) XOR sum_reg(31);
			sum_reg(25) <= sum_reg(17) XOR sum_reg(26) XOR sum_reg(27);
			sum_reg(26) <= sum_reg(18) XOR sum_reg(24) XOR sum_reg(27) XOR sum_reg(28) XOR sum_reg(30);
			sum_reg(27) <= sum_reg(19) XOR sum_reg(25) XOR sum_reg(28) XOR sum_reg(29) XOR sum_reg(31);
			sum_reg(28) <= sum_reg(20) XOR sum_reg(26) XOR sum_reg(29) XOR sum_reg(30);
			sum_reg(29) <= sum_reg(21) XOR sum_reg(27) XOR sum_reg(30) XOR sum_reg(31);
			sum_reg(30) <= sum_reg(22) XOR sum_reg(28) XOR sum_reg(31);
			sum_reg(31) <= sum_reg(23) XOR sum_reg(29);

		END IF;
	END PROCESS;

	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			fcs_error <= '0';
			IF end_flag = '1' AND end_cnt = 0 THEN
				IF sum_reg /= x"00_00_00_00" THEN
					fcs_error <= '1';
					--ELSE
					--end_flag <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;

END struc;
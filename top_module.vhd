LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
LIBRARY work;
USE work.global_var.ALL;

ENTITY top_module IS
    PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    -- inputs 
    data_in : IN rx_in;
    data_valid : IN rx_ctrl;

    -- outputs

    -- outputs to fcs check parallel
    );
END top_module;

ARCHITECTURE Behavioral OF top_module IS

    COMPONENT fcs_check_parallel
        PORT (
            clk : IN STD_LOGIC; -- system clock
            rst : IN STD_LOGIC; -- asynchronous rst

            data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- serial input data.
            valid : IN STD_LOGIC; -- indicates the validity of data_in.

            start_of_frame : IN STD_LOGIC; -- indicates the start of a frame.
            --end_of_frame : IN STD_LOGIC; -- indicates the end of a frame.

            is_data_valid : OUT STD_LOGIC -- indicates an error.
        );
    END COMPONENT;
    COMPONENT MAC_learning
        PORT (
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            mac_in : IN mac_input;
            valid : IN STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
            ready : OUT STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
            port_output : OUT mac_output;
            output_valid : OUT STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
            output_ready : IN STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0)
        );
    END COMPONENT;

BEGIN
    mac_l : MAC_learning
    PORT MAP(
        clk => clk,
        rst => rst,
        mac_in => s_data_to_mac_fifo,
        valid => s_data_valid_mac,
        ready => dead1,
        port_output => OPEN,
        output_valid => OPEN,
        output_ready => dead1
    );

    fcs_generate : FOR ii TO 0 TO 3 GENERATE
        u_fcs : fcs_check_parallel
        PORT MAP(
            clk => clk,
            rst => rst,
            data_in => s_data_to_fcs(ii),
            valid => s_data_valid(ii),
            start_of_frame => s_start_of_frame(ii),
            --end_of_frame => s_end_of_frame,
            is_data_valid => OPEN -- Or map to a signal if you need the result
        );
    END GENERATE fcs_generate;

END Behavioral;
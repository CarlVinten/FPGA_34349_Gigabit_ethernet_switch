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

END top_module;

ARCHITECTURE Behavioral OF top_module IS

    -- states

    TYPE state_type IS (state_idle, state_preamble, state_data);
    -- SIGNAL state : state_type := state_idle;

    TYPE state_array IS ARRAY (0 TO NUM_PORTS - 1) OF state_type;
    SIGNAL state : state_array := (OTHERS => state_idle);
    -- subtype arrays
    SUBTYPE preamble_range IS INTEGER RANGE 0 TO 7;
    SUBTYPE data_cnt_range IS INTEGER RANGE 0 TO 1514;
    SUBTYPE mac_addr_cnt_range IS INTEGER RANGE 0 TO 12;
    SUBTYPE ethertype_cnt_range IS INTEGER RANGE 0 TO 2;

    -- type arrays
    TYPE preamble_array IS ARRAY (0 TO NUM_PORTS - 1) OF INTEGER;
    TYPE data_cnt_array IS ARRAY (0 TO NUM_PORTS - 1) OF INTEGER;
    TYPE mac_addr_cnt_array IS ARRAY (0 TO NUM_PORTS - 1) OF INTEGER;
    TYPE ethertype_cnt_array IS ARRAY (0 TO NUM_PORTS - 1) OF INTEGER;

    -- signal / internal counters
    SIGNAL preamble_cnt : preamble_array := (OTHERS => 0);
    SIGNAL data_cnt : data_cnt_array := (OTHERS => 0);
    SIGNAL mac_addr_cnt : mac_addr_cnt_array := (OTHERS => 0);
    SIGNAL ethertype_cnt : ethertype_cnt_array := (OTHERS => 0);
    --SIGNAL start_of_frame : STD_LOGIC := '0';

    -- fcs signals
    SIGNAL s_data_to_fcs : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_data_valid : STD_LOGIC;
    SIGNAL s_start_of_frame : STD_LOGIC;
    SIGNAL s_data_to_switch_core_fifo : crossbar_input_array;

    SIGNAL dead1 : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL s_data_valid_mac : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_data_to_mac_fifo : mac_input;
    SIGNAL s_data_to_ethertype : STD_LOGIC_VECTOR(7 DOWNTO 0); -- not used

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
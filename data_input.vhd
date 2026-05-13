
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
LIBRARY work;
USE work.global_var.ALL;

ENTITY data_input IS
port(
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    data_in : IN rx_in;
    data_valid : IN rx_ctrl;

    data_to_crossbar : OUT crossbar_input_array;
    dst_port : OUT crossbar_dstport_array;
);
END ENTITY data_input;

ARCHITECTURE Behavioral OF data_input IS

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
    SIGNAL sof_to_fcs : STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
    SIGNAL s_valid_to_fcs : STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
    SIGNAL fcs_to_fsm : STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);

    -- mac 
    SIGNAL s_data_to_mac : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_valid_signal_high_for_mac : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL mac_to_fsm : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_rdy_signal_to_mac_from_fsm : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL valid_signal_to_fsm : STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);

    -- crossbar
    SIGNAL data_in_to_fifo : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data_fifo_to_fsm : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL fsm_to_dst_to_crossbar : crossbar_dstport_array;
    SIGNAL fsm_to_data_to_crossbar : crossbar_input_array;

BEGIN

    mac_l : MAC_learning
    PORT MAP(
        clk => clk,
        rst => rst,
        mac_in => s_data_to_mac,
        valid => s_valid_signal_high_for_mac,
        port_output => mac_to_fsm,
        output_valid => valid_signal_to_fsm,
        output_ready => s_rdy_signal_to_mac_from_fsm
    );

    gen : FOR i IN 0 TO NUM_PORTS - 1 GENERATE
        u_fcs : fcs_check_parallel
        PORT MAP(
            clk => clk,
            rst => rst,
            data_in => s_data_to_fcs(i),
            valid => s_valid_to_fcs(i),
            start_of_frame => sof_to_fcs(i),
            is_data_valid => fcs_to_fsm(i)
        );

        PROCESS (clk, rst)
        BEGIN
            -- data_fifo : 
            -- sof <= sof_to_fcs(i);

            IF rst = '1' THEN

                state(i) <= state_idle;
                preamble_cnt(i) <= 0;
                data_cnt(i) <= 0;
                mac_addr_cnt(i) <= 0;
                ethertype_cnt(i) <= 0;

            ELSIF rising_edge(clk) THEN
                -- data_to_fcs <= (OTHERS => '0');
                sof_to_fcs(i) <= '0';
                CASE state(i) IS
                    WHEN state_idle =>
                        sof_to_fcs(i) <= '0';
                        s_data_to_fcs(i) <= (OTHERS => '0');
                        preamble_cnt(i) <= 0;
                        data_cnt(i) <= 0;
                        mac_addr_cnt(i) <= 0;
                        ethertype_cnt(i) <= 0;

                        IF data_valid(i) = '1' THEN
                            IF data_in(i) = x"AA" THEN
                                preamble_cnt(i) <= preamble_cnt(i) + 1;
                            END IF;
                            state(i) <= state_preamble;

                        END IF;

                    WHEN state_preamble =>
                        IF data_in(i) = x"AA" AND data_valid(i) = '1' THEN
                            preamble_cnt(i) <= preamble_cnt(i) + 1;
                        END IF;

                        IF preamble_cnt(i) = 7 AND data_in(i) = x"AB" THEN
                            state(i) <= state_data;
                            sof_to_fcs(i) <= '1';
                        ELSIF data_valid(i) = '0' THEN
                            state(i) <= state_idle;
                        END IF;

                    WHEN state_data =>
                        IF state(i) = state_data AND data_valid(i) = '1' THEN
                            fcs_data_valid <= '1';
                        ELSE
                            fcs_data_valid <= '0';
                        END IF;
                        --       fcs_data_valid <= '1' WHEN state(i) = state_data AND data_valid(i) = '1' ELSE '0';
                        data_to_fcs <= data_in; -- Hooking up the internal signal to the output
                        s_data_to_fcs <= data_in;
                        data_cnt(i) <= data_cnt(i) + 1;

                        -- a little weird. they should all be 1's in here
                        IF data_valid(i) = '1' THEN
                            s_data_to_switch_core_fifo <= '1' & data_in(i);
                        ELSE
                            s_data_to_switch_core_fifo <= '0' & data_in(i);
                        END IF;

                        IF data_cnt(i) < 13 THEN
                            s_data_to_mac_fifo <= data_in(i);
                            -- mac addr_cnt <= mac_addr_cnt + 1;

                            -- ELSIF data_cnt(i) < 15 THEN
                            --     s_data_to_ethertype <= data_in(i);
                            -- ethertype_cnt <= ethertype_cnt + 1;

                        ELSIF data_valid(i) = '0' THEN
                            state(i) <= state_idle;
                        END IF;

                END CASE;
            END IF;

        END PROCESS;
    END GENERATE fcs_generate;

END Behavioral;
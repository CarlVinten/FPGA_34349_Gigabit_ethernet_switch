
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
    SIGNAL s_data_valid : STD_LOGIC;
    SIGNAL s_start_of_frame : STD_LOGIC;
    SIGNAL s_data_to_switch_core_fifo : crossbar_input_array;

    SIGNAL dead1 : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL s_data_valid_mac : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_data_to_mac_fifo : mac_input;
    SIGNAL s_data_to_ethertype : STD_LOGIC_VECTOR(7 DOWNTO 0); -- not used

   

  

    -- data_to_fcs <= s_data_to_fcs; 

    sof <= s_start_of_frame;
    -- data_to_fcs <= s_data_to_fcs;

        PROCESS (clk, rst)
        BEGIN

            IF rst = '1' THEN

                state(ii) <= state_idle;
                preamble_cnt(ii) <= 0;
                data_cnt(ii) <= 0;
                mac_addr_cnt(ii) <= 0;
                ethertype_cnt(ii) <= 0;

            ELSIF rising_edge(clk) THEN
                -- data_to_fcs <= (OTHERS => '0');
                s_start_of_frame(ii) <= '0';
                CASE state(ii) IS
                    WHEN state_idle =>
                        s_start_of_frame(ii) <= '0';
                        s_data_to_fcs(ii) <= (OTHERS => '0');
                        preamble_cnt(ii) <= 0;
                        data_cnt(ii) <= 0;
                        mac_addr_cnt(ii) <= 0;
                        ethertype_cnt(ii) <= 0;

                        IF data_valid = '1' THEN
                            IF data_in = x"AA" THEN
                                preamble_cnt(ii) <= preamble_cnt(ii) + 1;
                            END IF;
                            state(ii) <= state_preamble;

                        END IF;

                    WHEN state_preamble =>

                        IF data_in = x"AA" AND data_valid = '1' THEN
                            preamble_cnt(ii) <= preamble_cnt(ii) + 1;
                        END IF;

                        IF preamble_cnt(ii) = 7 AND data_in = x"AB" THEN
                            state(ii) <= state_data;
                            s_start_of_frame(ii) <= '1';
                        ELSIF data_valid = '0' THEN
                            state(ii) <= state_idle;
                        END IF;

                        -- WHEN state_SOF =>
                        --     IF data_in = x"AB" AND data_valid = '1' THEN
                        --         state(ii) <= state_data;
                        --     ELSIF data_valid = '0' THEN
                        --         state(ii) <= state_idle;
                        --     END IF;

                    WHEN state_data =>
                        IF state(ii) = state_data AND data_valid = '1' THEN
                            fcs_data_valid <= '1';
                        ELSE
                            fcs_data_valid <= '0';
                        END IF;
                        --       fcs_data_valid <= '1' WHEN state(ii) = state_data AND data_valid = '1' ELSE '0';
                        data_to_fcs <= data_in; -- Hooking up the internal signal to the output
                        s_data_to_fcs <= data_in;
                        data_cnt(ii) <= data_cnt(ii) + 1;

                        -- a little weird. they should all be 1's in here
                        IF data_valid = '1' THEN
                            s_data_to_switch_core_fifo <= '1' & data_in;
                        ELSE
                            s_data_to_switch_core_fifo <= '0' & data_in;
                        END IF;

                        IF data_cnt(ii) < 13 THEN
                            s_data_to_mac_fifo <= data_in;
                            -- mac addr_cnt <= mac_addr_cnt + 1;

                        ELSIF data_cnt(ii) < 15 THEN
                            s_data_to_ethertype <= data_in;
                            -- ethertype_cnt <= ethertype_cnt + 1;

                        ELSIF data_valid = '0' THEN
                            state(ii) <= state_idle;
                        END IF;

                END CASE;
            END IF;

        END PROCESS;
  END GENERATE fcs_generate;
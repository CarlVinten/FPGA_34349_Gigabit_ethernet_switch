
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
LIBRARY work;
USE work.global_var.ALL;

ENTITY data_input IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        data_in : IN rx_in;
        data_valid : IN rx_ctrl;

        data_to_crossbar : OUT crossbar_input_array;
        dst_port : OUT crossbar_dstport_array
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
            --ready : OUT STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0); 
            port_output : OUT mac_output;
            output_valid : OUT STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0);
            output_ready : IN STD_LOGIC_VECTOR(NUM_PORTS - 1 DOWNTO 0)
        );
    END COMPONENT;
    -- states

    COMPONENT crossbarfifo
        PORT (
            clock : IN STD_LOGIC;
            data : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
            rdreq : IN STD_LOGIC;
            sclr : IN STD_LOGIC;
            wrreq : IN STD_LOGIC;
            empty : OUT STD_LOGIC;
            full : OUT STD_LOGIC;
            q : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            usedw : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
        );
    END COMPONENT;

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

    -- fcs input signals
    SIGNAL fcs_data_in : fcs_data_input;
    SIGNAL fcs_sof : valid_signals;
    SIGNAL fcs_data_valid : valid_signals;

    -- fcs output signals
    SIGNAL fcs_valid_to_fsm : valid_signals;

    -- mac input signals
    SIGNAL mac_data_in : mac_input;
    SIGNAL mac_data_valid : valid_signals_vector;
    SIGNAL mac_rdy : valid_signals_vector; -- not used, but needed for the component

    -- mac output signals
    SIGNAL mac_data_to_fsm : mac_output; -- used
    SIGNAL mac_valid : valid_signals_vector; -- not used, but needed for the component

    -- crossbar
    SIGNAL data_in_to_fifo : crossbar_input_array; -- used
    SIGNAL data_out_to_fsm : crossbar_input_array;
    SIGNAL fsm_to_dst_to_crossbar : crossbar_dstport_array;
    SIGNAL fsm_to_data_to_crossbar : crossbar_input_array;

    -- deadsignals
    SIGNAL used_words_fifo : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL empty_fifo : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL full_fifo : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal rdreq_fifo : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal wrreq_fifo : STD_LOGIC_VECTOR(3 DOWNTO 0);

	-- Seconf FSM
	SIGNAL temp_dst_array: crossbar_dstport_array := (others => (others => '0'));
	SIGNAL is_filling_crossbar : std_logic_vector := "0000";
BEGIN

    mac_l : MAC_learning
    PORT MAP(
        clk => clk,
        rst => rst,
        mac_in => mac_data_in,
        valid => mac_data_valid,
        port_output => mac_data_to_fsm,
        output_valid => mac_valid,
        output_ready => mac_rdy
    );

    fcs_generate : FOR i IN 0 TO NUM_PORTS - 1 GENERATE
        u_fcs : fcs_check_parallel
        PORT MAP(
            clk => clk,
            rst => rst,
            data_in => fcs_data_in(i),
            valid => fcs_data_valid(i),
            start_of_frame => fcs_sof(i),
            is_data_valid => fcs_valid_to_fsm(i)
        );

        pack_fifo : crossbarfifo
        PORT MAP(
            clock => clk,
            data => data_in_to_fifo(i),
            rdreq => rdreq_fifo(i),
            sclr => rst,
            wrreq => wrreq_fifo(i),
            empty => empty_fifo(i),
            full => full_fifo(i),
            q => data_out_to_fsm(i),
            usedw => used_words_fifo
        );

        PROCESS (clk, rst)
        BEGIN
            -- data_fifo : 
            -- sof <= fcs_sof(i);

            IF rst = '1' THEN

                state(i) <= state_idle;
                -- fcs_sof(i) <= '0';
                -- fcs_data_valid(i) <= '0';
                mac_data_valid(i) <= '0';

                -- counters
                preamble_cnt(i) <= 0;
                data_cnt(i) <= 0;
                mac_addr_cnt(i) <= 0;
                ethertype_cnt(i) <= 0;

                -- data 
                fcs_data_in(i) <= (OTHERS => '0');
                data_in_to_fifo(i) <= (OTHERS => '0');
                mac_data_in(i) <= (OTHERS => '0');

            ELSIF rising_edge(clk) THEN
                CASE state(i) IS
                    WHEN state_idle =>
                        -- valid signals
                        fcs_sof(i) <= '0';
                        fcs_data_valid(i) <= '0';
                        mac_data_valid(i) <= '0';

                        -- counters
                        preamble_cnt(i) <= 0;
                        data_cnt(i) <= 0;
                        mac_addr_cnt(i) <= 0;
                        ethertype_cnt(i) <= 0;

                        -- data 
                        fcs_data_in(i) <= (OTHERS => '0');
                        data_in_to_fifo(i) <= (OTHERS => '0');
                        mac_data_in(i) <= (OTHERS => '0');

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
                            IF data_in(i) = x"AB" THEN
                                fcs_sof(i) <= '1';
                                fcs_data_valid(i) <= '1';
                            END IF;

                            state(i) <= state_data;
                            -- fcs_data_in(i) <= data_in(i);
                            -- data_cnt(i) <= data_cnt(i) + 1;
                            -- data_cnt(i) <= 0;

                            -- mac_data_valid(i) <= '1';
                            -- mac_data_in(i) <= data_in(i);

                            -- data_in_to_fifo(i) <= '1' & data_in(i);
                        ELSIF data_valid(i) = '0' THEN
                            state(i) <= state_idle;
                        END IF;

                    WHEN state_data =>
                        IF (state(i) = state_data OR data_valid(i) = '1') AND data_cnt(i) < 13 THEN
                            -- fcs
                            fcs_data_in(i) <= data_in(i);
                            data_cnt(i) <= data_cnt(i) + 1;
                            fcs_sof(i) <= '0';

                            -- mac
                            mac_data_in(i) <= data_in(i);
                            mac_data_valid(i) <= '1';

                            -- crossbar / fifo
                            -- fcs_sof(i) <= '0';

                        ELSIF state(i) = state_data AND data_valid(i) = '1' THEN
                            -- fcs
                            -- fcs_data_valid(i) <= '1';
                            data_cnt(i) <= data_cnt(i) + 1;
                            fcs_data_in(i) <= data_in(i);

                            -- mac
                            mac_data_valid(i) <= '0';

                            -- crossbar / fifo
                            data_in_to_fifo(i) <= '1' & data_in(i);

                            -- -- a little weird. they should all be 1's in here
                            -- IF data_valid(i) = '1' THEN

                            -- ELSE
                            --     s_data_to_switch_core_fifo(i) <= '0' & data_in(i);
                            -- END IF;

                        ELSIF data_valid(i) = '0' THEN
                            state(i) <= state_idle;
                            -- fcs_data_valid(i) <= '0';
                        END IF;

                END CASE;
            END IF;

        END PROCESS;


		PROCESS(clk) -- FSM to put data into crossbar from fifo.
		begin
			if(rising_edge(clock)) then
				temp_dst_array(i) <= temp_dst_array(i);
				crossbar_dstport_array(i) <= crossbar_dstport_array(i);

				if (is_data_valid(i) = '1') then
					is_filling_crossbar(i) <= '1';
				end if;

				if(data_out_to_fsm(8) = '1') then

				
				if (is_filling_crossbar(i) <= '1') then
					dst_port(i) <= crossbar_dstport_array(i);
				else
					dst_port(i) <= (others => '0');
				end if;



			end if;
		end process; 
    END GENERATE fcs_generate;

    -- Connect internal "lane" arrays to the physical output ports 
    data_to_crossbar <= data_in_to_fifo;
    --  dst_port         <= mac_data_to_fsm; 

    -- Drive the internal mac_rdy so the MAC component isn't stuck [cite: 20, 24]
    mac_rdy <= (OTHERS => '1');
END Behavioral;
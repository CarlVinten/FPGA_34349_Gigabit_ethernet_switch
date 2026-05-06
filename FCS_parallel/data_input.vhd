LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY data_input IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- inputs 
        data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_valid : IN STD_LOGIC;

        -- outputs
        data_to_switch_core_fifo : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
        data_to_mac_fifo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_to_ethertype : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        data_to_fcs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));

    -- data_to_valid_fifo : out  std_logic;

    --    data_ready : out  std_logic);
END data_input;

ARCHITECTURE Behavioral OF data_input IS
    -- change depending on how many states
    TYPE state_type IS (state_idle, state_preamble, state_data);
    SIGNAL state : state_type := state_idle;

    -- signal data_to_fifo_reg : std_logic_vector(8 downto 0) := (others => '0');
    SIGNAL preamble_cnt : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL data_cnt : INTEGER RANGE 0 TO 1514 := 0;

    SIGNAL mac_addr_cnt : INTEGER RANGE 0 TO 12 := 0;
    SIGNAL ethertype_cnt : INTEGER RANGE 0 TO 2 := 0;
    SIGNAL start_of_frame : STD_LOGIC := '0';

    -- signal state_idle : std_logic := '1';
    -- signal state_preamble : std_logic_vector(3 downto 0) := (others => '0');

    SIGNAL s_data_to_fcs : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_data_valid : STD_LOGIC;
    SIGNAL s_start_of_frame : STD_LOGIC;

    SIGNAL s_data_to_switch_core_fifo : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL s_data_to_mac_fifo : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_data_to_ethertype : STD_LOGIC_VECTOR(7 DOWNTO 0);

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

BEGIN

    u_fcs : fcs_check_parallel
    PORT MAP(
        clk => clk,
        rst => rst,
        data_in => s_data_to_fcs, -- Hooking up the internal signal
        valid => data_valid,
        start_of_frame => s_start_of_frame,
        --end_of_frame => s_end_of_frame,
        is_data_valid => OPEN -- Or map to a signal if you need the result
    ); 

    -- data_to_fcs <= s_data_to_fcs; 

    PROCESS (clk, rst)
    BEGIN

        IF rst = '1' THEN

            state <= state_idle;

        ELSIF rising_edge(clk) THEN

            -- data_temp <= data_in;

            CASE state IS
                WHEN state_idle =>

                    IF data_valid = '1' THEN
                        IF data_in = x"AA" THEN
                            preamble_cnt <= preamble_cnt + 1;
                        END IF;
                        state <= state_preamble;

                    END IF;

                WHEN state_preamble =>

                    IF data_in = x"AA" AND data_valid = '1' THEN
                        preamble_cnt <= preamble_cnt + 1;
                    END IF;

                    IF preamble_cnt = 7 and data_in =x"AB" THEN
                        state <= state_data;
                    ELSIF data_valid = '0' THEN
                        state <= state_idle;
                    END IF;

                -- WHEN state_SOF =>
                --     IF data_in = x"AB" AND data_valid = '1' THEN
                --         state <= state_data;
                --     ELSIF data_valid = '0' THEN
                --         state <= state_idle;
                --     END IF;

                WHEN state_data =>

                    s_data_to_fcs <= data_in;
                    data_cnt <= data_cnt + 1;

                    -- a little weird. they should all be 1's in here
                    IF data_valid = '1' THEN
                        s_data_to_switch_core_fifo <= '1' & data_in;
                    ELSE
                        s_data_to_switch_core_fifo <= '0' & data_in;
                    END IF;

                    IF data_cnt < 13 THEN
                        s_data_to_mac_fifo <= data_in;
                        -- mac addr_cnt <= mac_addr_cnt + 1;

                    ELSIF data_cnt < 15 THEN
                        s_data_to_ethertype <= data_in;
                        -- ethertype_cnt <= ethertype_cnt + 1;

                    ELSIF data_valid = '0' THEN
                        state <= state_idle;
                    END IF;

            END CASE;
        END IF;

    END PROCESS;

END Behavioral;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY data_input IS
    PORT (clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_valid : IN STD_LOGIC;
    
    data_to_switch_core_fifo : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    data_to_mac_fifo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_to_ethertype : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_to_fcs : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));

    -- data_to_valid_fifo : out  std_logic;

    --    data_ready : out  std_logic);
END data_input;

ARCHITECTURE Behavioral OF data_input IS


    -- change depending on how many states
    TYPE state_type IS (state_idle, state_preamble, state_SOF, state_data);
    SIGNAL state : state_type := state_idle;

    -- signal data_to_fifo_reg : std_logic_vector(8 downto 0) := (others => '0');
    SIGNAL preamble_cnt : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL data_cnt : INTEGER RANGE 0 TO 1514 := 0;

    SIGNAL mac_addr_cnt : INTEGER RANGE 0 TO 12 := 0;
    SIGNAL ethertype_cnt : INTEGER RANGE 0 TO 2 := 0;
    -- signal state_idle : std_logic := '1';
    -- signal state_preamble : std_logic_vector(3 downto 0) := (others => '0');
    -- signal start_of_frame : std_logic := '0';
   
BEGIN
 PROCESS (clk, rst)
    BEGIN

        IF rst = '1' THEN

            state <= state_idle;

        ELSIF rising_edge(clk) THEN

            -- data_temp <= data_in;

            CASE state IS
                WHEN state_idle =>
                    IF data_valid = '1' THEN
                        state <= state_preamble;
                    END IF;

                WHEN state_preamble =>

                    IF data_in = x"AA" AND data_valid = '1' THEN
                    IF preamble_cnt = 7 THEN
                        state <= state_SOF;
                    END IF;
                        preamble_cnt <= preamble_cnt + 1;
                    ELSIF data_valid = '0' THEN
                        state <= state_idle;
                    END IF;
                WHEN state_SOF =>
                    IF data_in = x"AB" AND data_valid = '1' THEN
                        state <= state_data;
                    ELSIF data_valid = '0' THEN
                        state <= state_idle;
                    END IF;

                WHEN state_data =>

                    data_to_fcs <= data_in;
                    data_cnt <= data_cnt + 1;

                    -- a little weird. they should all be 1's in here
                    IF data_valid = '1' THEN
                        data_to_switch_core_fifo <= '1' & data_in;
                    ELSE
                        data_to_switch_core_fifo <= '0' & data_in;
                    END IF;

                    IF data_cnt < 13 THEN
                        data_to_mac_fifo <= data_in;
                        -- mac addr_cnt <= mac_addr_cnt + 1;

                    ELSIF data_cnt < 15 THEN
                        data_to_ethertype <= data_in;
                        -- ethertype_cnt <= ethertype_cnt + 1;

                    ELSIF data_valid = '0' THEN
                        state <= state_idle;
                    END IF;

            END CASE;
        END IF;

    END PROCESS;

END Behavioral;
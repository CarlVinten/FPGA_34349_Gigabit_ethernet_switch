LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
ENTITY test IS
END;

ARCHITECTURE sim OF test IS

    COMPONENT fcs_check_parallel
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;

            data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            valid : IN STD_LOGIC;

            start_of_frame : IN STD_LOGIC;
            end_of_frame : IN STD_LOGIC;

            is_data_valid : OUT STD_LOGIC
        );
    END COMPONENT;

    -- SIGNALS 

    SIGNAL s_clk : STD_LOGIC := '0';
    SIGNAL s_reset : STD_LOGIC := '1';
    SIGNAL s_data_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_valid : STD_LOGIC := '0';
    SIGNAL s_is_data_valid : STD_LOGIC := '0';
    SIGNAL s_start_of_frame : STD_LOGIC := '1';
    SIGNAL s_end_of_frame : STD_LOGIC := '0';
    TYPE byte_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Change this to test different packet lengths (or make it empty)
    CONSTANT TEST_PACKET : byte_array := (
        -- Destination & Source MAC Addresses
        x"00", x"10", x"A4", x"7B", x"EA", x"80",
        x"00", x"12", x"34", x"56", x"78", x"90",
        -- Type/Length (IPv4)
        x"08", x"00",
        -- IP Header
        x"45", x"00", x"00", x"2E", x"B3", x"FE", x"00", x"00",
        x"80", x"11", x"05", x"40", x"C0", x"A8", x"00", x"2C",
        x"C0", x"A8", x"00", x"04",
        -- UDP Header
        x"04", x"00", x"04", x"00", x"00", x"1A", x"2D", x"E8",
        -- Payload Data
        x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07",
        x"08", x"09", x"0A", x"0B", x"0C", x"0D", x"0E", x"0F",
        x"10", x"11",
        -- Valid FCS Checksum 
        x"E6", x"C5", x"3D", x"B2"
    );

    --

BEGIN

    dut : COMPONENT fcs_check_parallel
        PORT MAP(
            clk => s_clk,
            reset => s_reset,
            data_in => s_data_in,
            valid => s_valid,
            is_data_valid => s_is_data_valid,
            start_of_frame => s_start_of_frame,
            end_of_frame => s_end_of_frame
        );

        clock_process : PROCESS
        BEGIN
            s_clk <= '0';
            WAIT FOR 4 ns;
            s_clk <= '1';
            WAIT FOR 4 ns;
        END PROCESS;

        reset_on_start : PROCESS
        BEGIN
            s_reset <= '1';
            WAIT FOR 10 ns;
            s_reset <= '0';
            WAIT;
        END PROCESS;

        --  valid_signal : PROCESS
        --BEGIN

        --END PROCESS;

        stimulus_process : PROCESS
        BEGIN

            s_data_in <= (OTHERS => '0');
            s_valid <= '0';
            s_start_of_frame <= '0';
            s_end_of_frame <= '0';

            WAIT FOR 15 ns;

            WAIT UNTIL rising_edge(s_clk);

            WAIT FOR 1 ns;

            s_start_of_frame <= '1';

            -- IF s_start_of_frame = '1' THEN
            IF TEST_PACKET'LENGTH > 0 OR s_start_of_frame = '1' THEN
                FOR i IN test_packet'RANGE LOOP
                    s_valid <= '1';
                    s_data_in <= TEST_PACKET(i);

                    WAIT UNTIL rising_edge(s_clk);
                    s_start_of_frame <= '0';
                END LOOP;
            END IF;
            -- END IF;

            s_end_of_frame <= '1';
            s_valid <= '0'; -- single data
            s_data_in <= (OTHERS => '0');

            WAIT FOR 100 ns;
        END PROCESS;

    END sim;
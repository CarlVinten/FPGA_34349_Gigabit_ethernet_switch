LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
LIBRARY work;
USE work.global_var.ALL;

ENTITY test IS
END;

ARCHITECTURE simData OF test IS

    COMPONENT data_input IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            data_in : IN rx_in;
            data_valid : IN rx_ctrl;
            data_to_crossbar : OUT crossbar_input_array;
            dst_port : OUT crossbar_dstport_array
        );
    END COMPONENT;

    -- general signals
    SIGNAL s_clk : STD_LOGIC := '0';
    SIGNAL s_rst : STD_LOGIC := '1';
    
    SIGNAL tb_in : rx_in := (OTHERS => (OTHERS => '0'));
    SIGNAL tb_ctrl : rx_ctrl := (OTHERS => '0');

    -- output of data input to crossbar
    SIGNAL tb_crossbar_out : crossbar_input_array := (OTHERS => (OTHERS => '0'));
    SIGNAL tb_dst_port_out : crossbar_dstport_array := (OTHERS => (OTHERS => '0'));

    -- constant
    CONSTANT clk_period : TIME := 8 ns;
    -- -- SIGNALS for data input
    -- SIGNAL u_data_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    -- SIGNAL u_valid : STD_LOGIC := '0';
    -- -- signals for fcs check parallel

    -- -- signals connecting fcs and data input
    -- SIGNAL f_start_of_frame : STD_LOGIC := '0';
    -- SIGNAL f_fcs_data_bridge : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- SIGNAL f_sof_bridge : STD_LOGIC := '0';
    -- SIGNAL f_valid_bridge : STD_LOGIC := '0';
    -- -- SIGNAL s_end_of_frame : STD_LOGIC := '0';
    -- -- signals out of fcs check parallel (NOT USED)
    -- SIGNAL s_is_data_valid : STD_LOGIC := '0';

    TYPE byte_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Change this to test different packet lengths (or make it empty)
    CONSTANT PACKET_1 : byte_array := (

        x"11", -- garbage -- !!!!!!!!!!!!!!!! kom tilbage for at spørge

        x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", -- Preamble

        x"AB", -- Start of Frame Delimiter

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

    -- Procedure to send a packet to a specific port
    PROCEDURE send_packet(
        SIGNAL port_data : OUT rx_in;
        SIGNAL port_ctrl : OUT rx_ctrl;
        CONSTANT port_num : IN INTEGER;
        CONSTANT pkt : IN byte_array
    ) IS
    BEGIN
        FOR i IN pkt'RANGE LOOP
            port_ctrl(port_num) <= '1';
            port_data(port_num) <= pkt(i);
            WAIT UNTIL rising_edge(s_clk);
        END LOOP;
        port_ctrl(port_num) <= '0';
        port_data(port_num) <= (OTHERS => '0');
        WAIT UNTIL rising_edge(s_clk);
    END PROCEDURE;

BEGIN

    DUT : data_input
    PORT MAP(
        clk => s_clk,
        rst => s_rst,
        data_in => tb_in,
        data_valid => tb_ctrl,
        data_to_crossbar => tb_crossbar_out,
        dst_port => tb_dst_port_out
    );

    s_clk <= NOT s_clk AFTER clk_period / 2;

    stimulus_process : PROCESS
    BEGIN

        s_rst <= '1';
        WAIT FOR 20 ns;
        s_rst <= '0';
        WAIT FOR 20 ns;

        WAIT UNTIL rising_edge(s_clk);
        send_packet(tb_in, tb_ctrl, 0, PACKET_1);

        WAIT FOR clk_period * 10; -- 

        -- Start Port 1
        tb_ctrl(1) <= '1';
        tb_in(1)   <= PACKET_1(0);
        -- Start Port 3 (Staggered by 1 clock if desired, or same time)
        tb_ctrl(3) <= '1';
        tb_in(3)   <= PACKET_1(0);
        
        WAIT UNTIL rising_edge(s_clk);

        -- Continue sending the rest of the packets
        FOR i IN 1 TO PACKET_1'HIGH LOOP
            tb_in(1) <= PACKET_1(i);
            tb_in(3) <= PACKET_1(i);
            WAIT UNTIL rising_edge(s_clk);
        END LOOP;
        
        tb_ctrl(1) <= '0';
        tb_ctrl(3) <= '0';
        tb_in(1)   <= (OTHERS => '0');
        tb_in(3)   <= (OTHERS => '0');

        WAIT FOR 200 ns;
        REPORT "Simulation Finished";
        WAIT;
    END PROCESS;



    --     -- -- IF s_start_of_frame = '1' THEN
    --     IF TEST_PACKET'LENGTH > 0 THEN
    --         FOR i IN test_packet'RANGE LOOP
    --             u_valid <= '1';
    --             u_data_in <= TEST_PACKET(i);

    --             WAIT UNTIL rising_edge(s_clk);
    --             -- f_sof_bridge <= '0';
    --         END LOOP;
    --     END IF;
    --     -- -- END IF;

    --     -- s_end_of_frame <= '1';
    --     -- s_valid <= '0'; -- single data
    --     -- s_data_in <= (OTHERS => '0');

    --     -- WAIT FOR 100 ns;
    -- END PROCESS;

END simData;
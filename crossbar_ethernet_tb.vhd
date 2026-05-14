library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.global_var.all;

entity crossbar_ethernet_tb is
end crossbar_ethernet_tb;

architecture tb of crossbar_ethernet_tb is

    -- Component declaration
    COMPONENT crossbar
        PORT (
            clock           : IN STD_LOGIC;
            rst             : IN STD_LOGIC;
            data            : IN crossbar_input_array;
            dstport         : IN crossbar_dstport_array;
            output1         : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            output2         : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            output3         : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            output4         : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            -- TX control signals
            tx_ctrl0        : OUT STD_LOGIC;
            tx_ctrl1        : OUT STD_LOGIC;
            tx_ctrl2        : OUT STD_LOGIC;
            tx_ctrl3        : OUT STD_LOGIC;
            -- Debug ports
            debug_fifo2_wrreq  : OUT STD_LOGIC;
            debug_fifo2_rdreq  : OUT STD_LOGIC;
            debug_fifo2_empty  : OUT STD_LOGIC;
            debug_fifo2_full   : OUT STD_LOGIC;
            debug_fifo2_usedw  : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
            debug_tx_state_1   : OUT STD_LOGIC;
            debug_tx_src_1     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            debug_rr_turn_tx_1 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;

    -- Test signals
    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '0';
    signal data_in              : crossbar_input_array := (others => (others => '0'));
    signal dstport_in           : crossbar_dstport_array := (others => (others => '0'));
    
    signal output1_data         : std_logic_vector(8 downto 0);
    signal output2_data         : std_logic_vector(8 downto 0);
    signal output3_data         : std_logic_vector(8 downto 0);
    signal output4_data         : std_logic_vector(8 downto 0);
    
    -- TX control signals
    signal tx_ctrl0             : std_logic;
    signal tx_ctrl1             : std_logic;
    signal tx_ctrl2             : std_logic;
    signal tx_ctrl3             : std_logic;
    
    -- Debug signals
    signal debug_fifo2_wrreq    : std_logic;
    signal debug_fifo2_rdreq    : std_logic;
    signal debug_fifo2_empty    : std_logic;
    signal debug_fifo2_full     : std_logic;
    signal debug_fifo2_usedw    : std_logic_vector(11 downto 0);
    signal debug_tx_state_1     : std_logic;
    signal debug_tx_src_1       : std_logic_vector(1 downto 0);
    signal debug_rr_turn_tx_1   : std_logic_vector(1 downto 0);

    -- Ethernet frame: 64 bytes = 512 bits
    -- Frame: 00_10_A4_7B_EA_80_00_12_34_56_78_90_08_00_45_00_00_2E_B3_FE_00_00_80_11_05_40_C0_A8_00_2C_C0_A8_00_04_04_00_04_00_00_1A_2D_E8_00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_E6_C5_3D_B2
    
    -- Frame stored as array of bytes for easier iteration
    type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);
    constant ETHERNET_FRAME : byte_array_t(0 to 63) := (
        x"00", x"10", x"A4", x"7B", x"EA", x"80", x"00", x"12",
        x"34", x"56", x"78", x"90", x"08", x"00", x"45", x"00",
        x"00", x"2E", x"B3", x"FE", x"00", x"00", x"80", x"11",
        x"05", x"40", x"C0", x"A8", x"00", x"2C", x"C0", x"A8",
        x"00", x"04", x"04", x"00", x"04", x"00", x"00", x"1A",
        x"2D", x"E8", x"00", x"01", x"02", x"03", x"04", x"05",
        x"06", x"07", x"08", x"09", x"0A", x"0B", x"0C", x"0D",
        x"0E", x"0F", x"10", x"11", x"E6", x"C5", x"3D", x"B2"
    );

    constant CLK_PERIOD : time := 10 ns;
    constant NUM_BYTES  : integer := 64;

begin

    -- Instantiate DUT
    dut : crossbar PORT MAP (
        clock              => clk,
        rst                => rst,
        data               => data_in,
        dstport            => dstport_in,
        output1            => output1_data,
        output2            => output2_data,
        output3            => output3_data,
        output4            => output4_data,
        tx_ctrl0           => tx_ctrl0,
        tx_ctrl1           => tx_ctrl1,
        tx_ctrl2           => tx_ctrl2,
        tx_ctrl3           => tx_ctrl3,
        debug_fifo2_wrreq  => debug_fifo2_wrreq,
        debug_fifo2_rdreq  => debug_fifo2_rdreq,
        debug_fifo2_empty  => debug_fifo2_empty,
        debug_fifo2_full   => debug_fifo2_full,
        debug_fifo2_usedw  => debug_fifo2_usedw,
        debug_tx_state_1   => debug_tx_state_1,
        debug_tx_src_1     => debug_tx_src_1,
        debug_rr_turn_tx_1 => debug_rr_turn_tx_1
    );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_process;

    -- Main stimulus process
    -- This process feeds the ethernet frame into input port 0
    -- and routes it to output port 1 (using dstport encoding: 0001 for port 1)
    stimulus : process
        variable byte_idx : integer;
        variable is_eop   : std_logic;
    begin
        -- Initialize
        data_in <= (others => (others => '0'));
        dstport_in <= (others => (others => '0'));
        rst <= '1';  -- Assert reset initially
        
        wait for 2 * CLK_PERIOD;
        rst <= '0';  -- Release reset
        wait for CLK_PERIOD;
        
        -- ========================================
        -- TEST 1: Send frame until halfway, then reset
        -- ========================================
        report "TEST 1: Starting frame transmission with reset in the middle...";
        report "Source: Input 0, Destination: Output 1 (port code: 0001)";
        report "Frame size: " & integer'image(NUM_BYTES) & " bytes";
        
        for byte_idx in 0 to NUM_BYTES - 1 loop
            -- Stop transmission and assert reset halfway through the frame
            if byte_idx = 32 then
                report "*** ASSERTING RESET at byte " & integer'image(byte_idx) & " ***";
                rst <= '1';
                data_in <= (others => (others => '0'));
                dstport_in <= (others => (others => '0'));
                wait for 2 * CLK_PERIOD;
                rst <= '0';
                report "*** RESET DEASSERTED ***";
                wait for CLK_PERIOD;
                -- Exit this test after reset
                exit;
            end if;
            
            -- Set the destination port for input 0 to output 1
            dstport_in(0) <= "0001";  -- Route input 0 to output 1
            
            -- Set end-of-packet flag on last byte (bit 8 = 1)
            if byte_idx = NUM_BYTES - 1 then
                is_eop := '1';
            else
                is_eop := '0';
            end if;
            
            -- Load the byte into input 0 (data(0))
            -- Format: [EoP][data(7..0)]
            data_in(0) <= is_eop & ETHERNET_FRAME(byte_idx);
            
            -- Keep other inputs idle
            data_in(1) <= "0" & x"00";
            data_in(2) <= "0" & x"00";
            data_in(3) <= "0" & x"00";
            
            wait for CLK_PERIOD;
            
            -- Print progress every 8 bytes
            if (byte_idx + 1) mod 8 = 0 then
                report "Transmitted " & integer'image(byte_idx + 1) & " bytes before reset";
            end if;
        end loop;
        
        -- Stop sending data and wait
        data_in <= (others => (others => '0'));
        dstport_in <= (others => (others => '0'));
        report "Waiting for crossbar to settle after reset...";
        wait for 100 * CLK_PERIOD;
        
        -- ========================================
        -- TEST 2: Send complete frame after reset
        -- ========================================
        report "TEST 2: Sending complete frame after reset to verify normal operation...";
        report "Source: Input 0, Destination: Output 1 (port code: 0001)";
        
        for byte_idx in 0 to NUM_BYTES - 1 loop
            -- Set the destination port for input 0 to output 1
            dstport_in(0) <= "0001";  -- Route input 0 to output 1
            
            -- Set end-of-packet flag on last byte (bit 8 = 1)
            if byte_idx = NUM_BYTES - 1 then
                is_eop := '1';
            else
                is_eop := '0';
            end if;
            
            -- Load the byte into input 0 (data(0))
            -- Format: [EoP][data(7..0)]
            data_in(0) <= is_eop & ETHERNET_FRAME(byte_idx);
            
            -- Keep other inputs idle
            data_in(1) <= "0" & x"00";
            data_in(2) <= "0" & x"00";
            data_in(3) <= "0" & x"00";
            
            wait for CLK_PERIOD;
            
            -- Print progress every 8 bytes
            if (byte_idx + 1) mod 8 = 0 then
                report "Transmitted " & integer'image(byte_idx + 1) & " bytes";
            end if;
        end loop;
        
        -- Stop sending data
        data_in <= (others => (others => '0'));
        dstport_in <= (others => (others => '0'));
        
        report "Transmission complete. Waiting for data to be read from output...";
        
        -- Wait for a reasonable amount of time for data to propagate through the crossbar
        wait for 100 * CLK_PERIOD;
        
        report "Test completed.";
        wait;
        
    end process stimulus;

    -- Monitor output 1 (where we expect the frame to appear)
    output_monitor : process(clk)
        variable byte_count : integer := 0;
    begin
        if rising_edge(clk) then
            -- Check if there's valid data on output 1
            if output1_data(8) = '0' and output1_data(7 downto 0) /= x"00" then
                report "Output 1: Received byte (decimal: " & integer'image(to_integer(unsigned(output1_data(7 downto 0)))) & 
                        "), EoP=" & std_logic'image(output1_data(8)) & ", Byte #" & integer'image(byte_count);
                byte_count := byte_count + 1;
            elsif output1_data(8) = '1' then
                report "Output 1: Received last byte (EoP, decimal: " & integer'image(to_integer(unsigned(output1_data(7 downto 0)))) & ")";
                byte_count := byte_count + 1;
            end if;
        end if;
    end process output_monitor;

    -- Monitor TX control signals (edge detection)
    tx_ctrl_monitor : process(clk)
        variable prev_tx_ctrl0 : std_logic := '0';
        variable prev_tx_ctrl1 : std_logic := '0';
        variable prev_tx_ctrl2 : std_logic := '0';
        variable prev_tx_ctrl3 : std_logic := '0';
    begin
        if rising_edge(clk) then
            -- Output 0 (tx_ctrl0)
            if tx_ctrl0 = '1' and prev_tx_ctrl0 = '0' then
                report "TX_CTRL0: Output 1 TRANSMISSION STARTED";
            elsif tx_ctrl0 = '0' and prev_tx_ctrl0 = '1' then
                report "TX_CTRL0: Output 1 TRANSMISSION ENDED";
            end if;
            prev_tx_ctrl0 := tx_ctrl0;
            
            -- Output 1 (tx_ctrl1)
            if tx_ctrl1 = '1' and prev_tx_ctrl1 = '0' then
                report "TX_CTRL1: Output 2 TRANSMISSION STARTED";
            elsif tx_ctrl1 = '0' and prev_tx_ctrl1 = '1' then
                report "TX_CTRL1: Output 2 TRANSMISSION ENDED";
            end if;
            prev_tx_ctrl1 := tx_ctrl1;
            
            -- Output 2 (tx_ctrl2)
            if tx_ctrl2 = '1' and prev_tx_ctrl2 = '0' then
                report "TX_CTRL2: Output 3 TRANSMISSION STARTED";
            elsif tx_ctrl2 = '0' and prev_tx_ctrl2 = '1' then
                report "TX_CTRL2: Output 3 TRANSMISSION ENDED";
            end if;
            prev_tx_ctrl2 := tx_ctrl2;
            
            -- Output 3 (tx_ctrl3)
            if tx_ctrl3 = '1' and prev_tx_ctrl3 = '0' then
                report "TX_CTRL3: Output 4 TRANSMISSION STARTED";
            elsif tx_ctrl3 = '0' and prev_tx_ctrl3 = '1' then
                report "TX_CTRL3: Output 4 TRANSMISSION ENDED";
            end if;
            prev_tx_ctrl3 := tx_ctrl3;
        end if;
    end process tx_ctrl_monitor;

    -- Debug monitor for FIFO 2 (output 2, input 0)
    debug_monitor : process(clk)
    begin
        if rising_edge(clk) then
            if debug_fifo2_wrreq = '1' then
                report "FIFO 2 Write: usedw=" & integer'image(to_integer(unsigned(debug_fifo2_usedw)));
            end if;
        end if;
    end process debug_monitor;

end tb;

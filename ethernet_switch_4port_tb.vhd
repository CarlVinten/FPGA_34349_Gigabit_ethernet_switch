library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
LIBRARY work;
USE work.global_var.ALL;

entity ethernet_switch_4port_tb is
end ethernet_switch_4port_tb;

architecture tb of ethernet_switch_4port_tb is
    -- Component declaration for the 4-port ethernet switch
    component top_module
        port (
            clk : IN STD_LOGIC;
		    rst : IN STD_LOGIC;

		    -- inputs 
		    data_in : IN rx_in;
		    data_in_valid : IN std_logic_vector(NUM_PORTS - 1 downto 0);

		    -- outputs
			data_out : OUT tx_out;
			data_out_valid : OUT std_logic_vector(NUM_PORTS - 1 downto 0)
        );
    end component;
    
    -- Test signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
	SIGNAL RX : rx_in := (others => (others => '0'));
    signal RX_control   : std_logic_vector(3 downto 0) := (others => '0');

    SIGNAL TX : tx_out := (others => (others => '0'));
	signal TX_control   : std_logic_vector(3 downto 0);
    

    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
    -- Ethernet packet data
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

begin
    -- DUT instantiation
    DUT : top_module
        port map (
            clk => clk,
		    rst => rst,

		    -- inputs 
		    data_in => RX,
		    data_in_valid => RX_control,

		    -- outputs
			data_out =>	TX,
			data_out_valid => TX_control
        );
    
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_process;
    
    -- File I/O for packet data
    
    
    -- Test stimulus
    stimulus : process
        variable packet_index : integer;
    begin
        -- Reset assertion
        rst <= '1';
        RX_control <= "0000";
        RX(0) <= (others => '0');
        RX(1) <= (others => '0');
        RX(2) <= (others => '0');
        RX(3) <= (others => '0');
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;
        
        -- Set RX_control high for entire packet reception
        RX_control(0) <= '1';
        RX_control(3 downto 1) <= "000";
        
        -- Apply ethernet frame data to port 0
        for packet_index in ETHERNET_FRAME'range loop
            RX(0) <= ETHERNET_FRAME(packet_index);
            
            -- Keep other ports inactive
            RX(1) <= (others => '0');
            RX(2) <= (others => '0');
            RX(3) <= (others => '0');
            wait for CLK_PERIOD;
        end loop;
        
        -- Stop all signals
        RX_control <= "0000";
		RX <= (others => (others => '0'));
        wait for CLK_PERIOD * 10;
        
        -- End simulation
        wait;
    end process stimulus;
    
    -- Monitor process to capture TX output on port 0
    monitor : process
        file tx_output_file : text;
        variable line_buffer : line;
    begin
        -- Open output file for writing
        file_open(tx_output_file, "tx_output.txt", write_mode);
        
        -- Monitor TX port 0 continuously
        loop
            wait for CLK_PERIOD;
            
            -- Capture data when TX_control(0) is high
            if TX_control(0) = '1' then
                hwrite(line_buffer, TX(0));
                writeline(tx_output_file, line_buffer);
            end if;
        end loop;
        
        -- Close output file when done
        file_close(tx_output_file);
        wait;
    end process monitor;

end architecture tb;

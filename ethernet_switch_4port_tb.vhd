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
    procedure read_packet_file(
        filename    : string;
        port_data   : out std_logic_vector(7 downto 0);
        port_valid  : out boolean;
        file_handle : inout text
    ) is
        variable line_buffer : line;
        variable data_value  : std_logic_vector(7 downto 0);
        variable read_ok     : boolean;
    begin
        port_valid := false;
        port_data := (others => '0');
        
        if not endfile(file_handle) then
            readline(file_handle, line_buffer);
            hread(line_buffer, data_value, read_ok);
            if read_ok then
                port_data := data_value;
                port_valid := true;
            end if;
        end if;
    end procedure read_packet_file;

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
        file rx0_file : text;
        
        variable rx0_valid : boolean := false;
        variable rx0_data : std_logic_vector(7 downto 0);
        
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
        
        -- Open packet file
        file_open(rx0_file, "fpga_test_packets/packet_01.txt", read_mode);
        
        -- Read and apply packets until file is exhausted
        loop
            -- Read from packet file
            read_packet_file("fpga_test_packets/packet_01.txt", rx0_data, rx0_valid, rx0_file);
            
            if not rx0_valid then
                exit;  -- Exit loop when file exhausted
            end if;
            
            -- Apply data to port 0
            if rx0_valid then
                RX(0) <= rx0_data;
                RX_control(0) <= '1';
            else
                RX(0) <= (others => '0');
                RX_control(0) <= '0';
            end if;
            
            -- Keep other ports inactive
            RX(1) <= (others => '0');
            RX(2) <= (others => '0');
            RX(3) <= (others => '0');
            RX_control(3 downto 1) <= "000";
            wait for CLK_PERIOD;
        end loop;
        
        -- Close file
        file_close(rx0_file);
        
        -- Stop all signals
        RX_control <= "0000";
		RX <= (others => (others => '0'));
        wait for CLK_PERIOD * 10;
        
        -- End simulation
        wait;
    end process stimulus;

end architecture tb;

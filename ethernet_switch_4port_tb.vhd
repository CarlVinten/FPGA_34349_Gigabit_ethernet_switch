library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity ethernet_switch_4port_tb is
end ethernet_switch_4port_tb;

architecture tb of ethernet_switch_4port_tb is
    -- Component declaration for the 4-port ethernet switch
    component ethernet_switch_4port
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            
            -- RX ports
            RX0         : in  std_logic_vector(7 downto 0);
            RX1         : in  std_logic_vector(7 downto 0);
            RX2         : in  std_logic_vector(7 downto 0);
            RX3         : in  std_logic_vector(7 downto 0);
            RX_control  : in  std_logic_vector(3 downto 0);
            
            -- TX ports
            TX0         : out std_logic_vector(7 downto 0);
            TX1         : out std_logic_vector(7 downto 0);
            TX2         : out std_logic_vector(7 downto 0);
            TX3         : out std_logic_vector(7 downto 0);
            TX_control  : out std_logic_vector(3 downto 0)
        );
    end component;
    
    -- Test signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal RX0          : std_logic_vector(7 downto 0) := (others => '0');
    signal RX1          : std_logic_vector(7 downto 0) := (others => '0');
    signal RX2          : std_logic_vector(7 downto 0) := (others => '0');
    signal RX3          : std_logic_vector(7 downto 0) := (others => '0');
    signal RX_control   : std_logic_vector(3 downto 0) := (others => '0');
    
    signal TX0          : std_logic_vector(7 downto 0);
    signal TX1          : std_logic_vector(7 downto 0);
    signal TX2          : std_logic_vector(7 downto 0);
    signal TX3          : std_logic_vector(7 downto 0);
    signal TX_control   : std_logic_vector(3 downto 0);
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;
    
begin
    -- DUT instantiation
    DUT : ethernet_switch_4port
        port map (
            clk         => clk,
            rst         => rst,
            RX0         => RX0,
            RX1         => RX1,
            RX2         => RX2,
            RX3         => RX3,
            RX_control  => RX_control,
            TX0         => TX0,
            TX1         => TX1,
            TX2         => TX2,
            TX3         => TX3,
            TX_control  => TX_control
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
    
    -- Test stimulus
    stimulus : process
        file rx0_file : text;
        file rx1_file : text;
        file rx2_file : text;
        file rx3_file : text;
        
        variable rx0_valid : boolean := false;
        variable rx1_valid : boolean := false;
        variable rx2_valid : boolean := false;
        variable rx3_valid : boolean := false;
        
        variable rx0_data : std_logic_vector(7 downto 0);
        variable rx1_data : std_logic_vector(7 downto 0);
        variable rx2_data : std_logic_vector(7 downto 0);
        variable rx3_data : std_logic_vector(7 downto 0);
        
        variable any_active : boolean;
        
    begin
        -- Reset assertion
        rst <= '1';
        RX_control <= "0000";
        RX0 <= (others => '0');
        RX1 <= (others => '0');
        RX2 <= (others => '0');
        RX3 <= (others => '0');
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;
        
        -- Open packet files
        file_open(rx0_file, "rx0_packets.txt", read_mode);
        file_open(rx1_file, "rx1_packets.txt", read_mode);
        file_open(rx2_file, "rx2_packets.txt", read_mode);
        file_open(rx3_file, "rx3_packets.txt", read_mode);
        
        -- Read and apply packets until all files are exhausted
        loop
            -- Read from each file
            read_packet_file("rx0_packets.txt", rx0_data, rx0_valid, rx0_file);
            read_packet_file("rx1_packets.txt", rx1_data, rx1_valid, rx1_file);
            read_packet_file("rx2_packets.txt", rx2_data, rx2_valid, rx2_file);
            read_packet_file("rx3_packets.txt", rx3_data, rx3_valid, rx3_file);
            
            -- Check if any port has valid data
            any_active := rx0_valid or rx1_valid or rx2_valid or rx3_valid;
            
            if not any_active then
                exit;  -- Exit loop when all files exhausted
            end if;
            
            -- Apply data to ports
            if rx0_valid then
                RX0 <= rx0_data;
            else
                RX0 <= (others => '0');
            end if;
            
            if rx1_valid then
                RX1 <= rx1_data;
            else
                RX1 <= (others => '0');
            end if;
            
            if rx2_valid then
                RX2 <= rx2_data;
            else
                RX2 <= (others => '0');
            end if;
            
            if rx3_valid then
                RX3 <= rx3_data;
            else
                RX3 <= (others => '0');
            end if;
            
            -- Update control signal (active low for valid ports)
            RX_control(0) <= '1' when rx0_valid else '0';
            RX_control(1) <= '1' when rx1_valid else '0';
            RX_control(2) <= '1' when rx2_valid else '0';
            RX_control(3) <= '1' when rx3_valid else '0';
            
            wait for CLK_PERIOD;
        end loop;
        
        -- Close files
        file_close(rx0_file);
        file_close(rx1_file);
        file_close(rx2_file);
        file_close(rx3_file);
        
        -- Stop all signals
        RX_control <= "0000";
        RX0 <= (others => '0');
        RX1 <= (others => '0');
        RX2 <= (others => '0');
        RX3 <= (others => '0');
        wait for CLK_PERIOD * 10;
        
        -- End simulation
        wait;
    end process stimulus;

end architecture tb;

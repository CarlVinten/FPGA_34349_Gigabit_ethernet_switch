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
    
    -- Packet types
    type byte_array_t is array(integer range <>) of std_logic_vector(7 downto 0);
    
    -- Packet 1: Broadcast from MAC 00:10:A4:7B:EA:80
    -- Dest: FF:FF:FF:FF:FF:FF (broadcast)
    -- This teaches the switch that MAC 00:10:A4:7B:EA:80 is on port 0
    -- Expected: packet broadcasts to all 4 output ports
    constant PACKET_1 : byte_array_t(0 to 71) := (
        x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AB",
        x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"10",
        x"A4", x"7B", x"EA", x"80", x"08", x"00", x"45", x"00",
        x"00", x"24", x"B3", x"FE", x"00", x"00", x"80", x"11",
        x"05", x"4A", x"C0", x"A8", x"00", x"2C", x"C0", x"A8",
        x"00", x"04", x"04", x"00", x"04", x"00", x"00", x"10",
        x"2D", x"E8", x"11", x"22", x"33", x"44", x"55", x"66",
        x"77", x"88", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"10", x"C4", x"46", x"04"
    );
    
    -- Packet 2: Unicast from MAC 00:99:88:77:66:55 TO 00:10:A4:7B:EA:80
    -- Dest: 00:10:A4:7B:EA:80 (the MAC we just learned from Packet 1)
    -- If MAC learning works: packet should forward ONLY to port 0 (unicast)
    -- If MAC learning fails: packet would broadcast to all ports
    constant PACKET_2 : byte_array_t(0 to 71) := (
        x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AA", x"AB",
        x"00", x"10", x"A4", x"7B", x"EA", x"80", x"00", x"99",
        x"88", x"77", x"66", x"55", x"08", x"00", x"45", x"00",
        x"00", x"24", x"B3", x"FE", x"00", x"00", x"80", x"11",
        x"05", x"4A", x"C0", x"A8", x"00", x"2C", x"C0", x"A8",
        x"00", x"04", x"04", x"00", x"04", x"00", x"00", x"10",
        x"2D", x"E8", x"AA", x"BB", x"CC", x"DD", x"EE", x"FF",
        x"00", x"11", x"00", x"00", x"00", x"00", x"00", x"00",
        x"00", x"00", x"00", x"00", x"BF", x"EC", x"96", x"D0"
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
    
    -- Test stimulus: Demonstrate MAC learning
    -- Phase 1: Send broadcast packet to teach port 0 MAC address
    -- Phase 2: Send unicast to that MAC to verify learned forwarding
    stimulus : process
        variable packet_index : integer;
    begin
        -- Reset assertion
        rst <= '1';
        RX_control <= "0000";
        RX <= (others => (others => '0'));
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;
        
        -- ========== PHASE 1: Send PACKET 1 (Broadcast) ==========
        -- This packet broadcasts from MAC 00:10:A4:7B:EA:80 to FF:FF:FF:FF:FF:FF
        -- Expected behavior: Switch learns MAC on port 0, broadcasts to all 4 ports
        
        RX_control(0) <= '1';
        RX_control(3 downto 1) <= "000";
        
        for packet_index in PACKET_1'range loop
            RX(0) <= PACKET_1(packet_index);
            RX(1) <= (others => '0');
            RX(2) <= (others => '0');
            RX(3) <= (others => '0');
            wait for CLK_PERIOD;
        end loop;
        
        -- Wait between packets to let switch process learning (200 clock cycles)
        RX_control <= "0000";
        RX <= (others => (others => '0'));
        wait for CLK_PERIOD * 200;
        
        -- ========== PHASE 2: Send PACKET 2 (Unicast) ==========
        -- This packet is sent TO 00:10:A4:7B:EA:80 from 00:99:88:77:66:55
        -- Expected behavior (if MAC learning works): 
        --   Output ONLY on port 0 (learned destination) instead of broadcast
        -- If MAC learning fails: would broadcast to all ports instead
        
        RX_control(0) <= '1';
        RX_control(3 downto 1) <= "000";
        
        for packet_index in PACKET_2'range loop
            RX(0) <= PACKET_2(packet_index);
            RX(1) <= (others => '0');
            RX(2) <= (others => '0');
            RX(3) <= (others => '0');
            wait for CLK_PERIOD;
        end loop;
        
        -- Stop all signals
        RX_control <= "0000";
        RX <= (others => (others => '0'));
        wait for CLK_PERIOD * 200;
        
        -- End simulation
        wait;
    end process stimulus;
    
    -- Monitor process to capture TX output and track which ports are active
    monitor : process
        file tx_output_file : text;
        variable line_buffer : line;
        variable port_activity : std_logic_vector(3 downto 0);
        variable prev_port_activity : std_logic_vector(3 downto 0) := "0000";
    begin
        -- Open output file for writing
        file_open(tx_output_file, "tx_output.txt", write_mode);
        write(line_buffer, string'("=== MAC LEARNING TEST ==="));
        writeline(tx_output_file, line_buffer);
        write(line_buffer, string'("Packet 1 (Broadcast): Dest=FF:FF:FF:FF:FF:FF, Source=00:10:A4:7B:EA:80"));
        writeline(tx_output_file, line_buffer);
        write(line_buffer, string'("  Expected: Output on ALL ports (broadcast)"));
        writeline(tx_output_file, line_buffer);
        write(line_buffer, string'("Packet 2 (Unicast): Dest=00:10:A4:7B:EA:80, Source=00:99:88:77:66:55"));
        writeline(tx_output_file, line_buffer);
        write(line_buffer, string'("  Expected: Output ONLY on port 0 (learned destination MAC)"));
        writeline(tx_output_file, line_buffer);
        write(line_buffer, string'(""));
        writeline(tx_output_file, line_buffer);
        
        -- Monitor TX continuously
        loop
            wait for CLK_PERIOD;
            
            -- Capture data when any TX_control is high
            port_activity := TX_control;
            
            if port_activity /= prev_port_activity then
                write(line_buffer, string'("Port activity changed to: "));
                write(line_buffer, port_activity);
                write(line_buffer, string'(" (Port 0="));
                write(line_buffer, port_activity(0));
                write(line_buffer, string'(" Port 1="));
                write(line_buffer, port_activity(1));
                write(line_buffer, string'(" Port 2="));
                write(line_buffer, port_activity(2));
                write(line_buffer, string'(" Port 3="));
                write(line_buffer, port_activity(3));
                write(line_buffer, string'(")"));
                writeline(tx_output_file, line_buffer);
                prev_port_activity := port_activity;
            end if;
            
            -- Log packet data when active
            if TX_control(0) = '1' then
                hwrite(line_buffer, TX(0));
                write(line_buffer, string'(" [Port 0]"));
                writeline(tx_output_file, line_buffer);
            end if;
            if TX_control(1) = '1' then
                hwrite(line_buffer, TX(1));
                write(line_buffer, string'(" [Port 1]"));
                writeline(tx_output_file, line_buffer);
            end if;
            if TX_control(2) = '1' then
                hwrite(line_buffer, TX(2));
                write(line_buffer, string'(" [Port 2]"));
                writeline(tx_output_file, line_buffer);
            end if;
            if TX_control(3) = '1' then
                hwrite(line_buffer, TX(3));
                write(line_buffer, string'(" [Port 3]"));
                writeline(tx_output_file, line_buffer);
            end if;
        end loop;
        
        -- Close output file when done
        file_close(tx_output_file);
        wait;
    end process monitor;

end architecture tb;

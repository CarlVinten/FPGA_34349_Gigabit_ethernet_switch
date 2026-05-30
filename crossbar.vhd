    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;
    library work;
    use work.global_var.all;

    LIBRARY altera_mf;
    USE altera_mf.altera_mf_components.all;


    entity crossbar is
        port
        (
            clock		: IN STD_LOGIC ;
            rst	    	: IN STD_LOGIC ;
            data		: IN crossbar_input_array;
            dstport 	: IN crossbar_dstport_array;
            output1		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output2		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output3		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output4		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            -- TX control signals (1 when transmitting, 0 when idle)
            tx_ctrl0    : OUT STD_LOGIC;
            tx_ctrl1    : OUT STD_LOGIC;
            tx_ctrl2    : OUT STD_LOGIC;
            tx_ctrl3    : OUT STD_LOGIC
        );
    end crossbar;


    architecture struc1 of crossbar is
        COMPONENT crossbarfifo
        PORT
        (
            clock		: IN STD_LOGIC ;
            data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
            rdreq		: IN STD_LOGIC ;
            sclr		: IN STD_LOGIC ;
            wrreq		: IN STD_LOGIC ;
            empty		: OUT STD_LOGIC ;
            full		: OUT STD_LOGIC ;
            q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
            usedw	: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
        );
    END COMPONENT;


    SIGNAL output1_mux: std_logic_vector(35 downto 0);
    SIGNAL output2_mux: std_logic_vector(35 downto 0);
    SIGNAL output3_mux: std_logic_vector(35 downto 0);
    SIGNAL output4_mux: std_logic_vector(35 downto 0);

    SIGNAL rdreq : STD_LOGIC_vector(15 downto 0);
    SIGNAL sclr  : STD_LOGIC;
    SIGNAL wrreq : STD_LOGIC;
    SIGNAL empty : STD_LOGIC_vector(15 downto 0);
    SIGNAL full  : STD_LOGIC_vector(15 downto 0);
    TYPE usedw_array_t IS ARRAY(15 downto 0) OF STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL usedw : usedw_array_t;

    TYPE state_array_t IS ARRAY (0 to 3) OF STD_LOGIC;
    TYPE int_array_t   IS ARRAY (0 to 3) OF integer range 0 to 3;

    -- '0' = IDLE/Arbitrate, '1' = TRANSMITTING a packet
    SIGNAL tx_state  : state_array_t := (others => '0');
    SIGNAL tx_src    : int_array_t := (others => 0);
    SIGNAL rr_turn_tx: int_array_t := (others => 0);

    -- Placeholder validity signal used by packet admission logic.
    SIGNAL rx_valid : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');



    SIGNAL rr_turn : integer range 0 to 3 := 0;

-- signal declarations 
SIGNAL state : STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";

SIGNAL write_enable : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');



begin

    -- The Round Robin Counter: Rotates the priority every clock cycle
    process(clock)
    begin
        if rising_edge(clock) then
            if rst = '1' then
                rr_turn <= 0;
            elsif rr_turn = 3 then
                rr_turn <= 0;
            else
                rr_turn <= rr_turn + 1; -- Increment directly instead of using rr_turn_next
            end if;
        end if;
    end process;

    sclr <= rst;
    wrreq <= '1';
    -- rdreq is driven by the arbiter process below.

    --port map for mem component

f1: crossbarfifo
port map (
    clock => clock,
    data => data(0),
    rdreq => rdreq(0),
    sclr => sclr,
    wrreq => dstport(0)(0),
    empty => empty(0),
    full => full(0),
    q => output1_mux(8 downto 0),
    usedw => usedw(0)
);
f2: crossbarfifo
port map (
    clock => clock,
    data => data(0),
    rdreq => rdreq(1),
    sclr => sclr,
    wrreq => dstport(0)(1),
    empty => empty(1),
    full => full(1),
    q => output2_mux(8 downto 0),
    usedw => usedw(1)
);
f3: crossbarfifo
port map (
    clock => clock,
    data => data(0),
    rdreq => rdreq(2),
    sclr => sclr,
    wrreq => dstport(0)(2),
    empty => empty(2),
    full => full(2),
    q => output3_mux(8 downto 0),
    usedw => usedw(2)
);
f4: crossbarfifo
port map (
    clock => clock,
    data => data(0),
    rdreq => rdreq(3),
    sclr => sclr,
    wrreq => dstport(0)(3),
    empty => empty(3),
    full => full(3),
    q => output4_mux(8 downto 0),
    usedw => usedw(3)
);
f5: crossbarfifo
port map (
    clock => clock,
    data => data(1), 
    rdreq => rdreq(4),
    sclr => sclr,
    wrreq => dstport(1)(0),
    empty => empty(4),
    full => full(4),
    q => output1_mux(17 downto 9), 
    usedw => usedw(4)
);
f6: crossbarfifo
port map (
    clock => clock,
    data => data(1), 
    rdreq => rdreq(5),
    sclr => sclr,
    wrreq => dstport(1)(1),
    empty => empty(5),
    full => full(5),
    q => output2_mux(17 downto 9), 
    usedw => usedw(5)
);
f7: crossbarfifo
port map (
    clock => clock,
    data => data(1), 
    rdreq => rdreq(6),
    sclr => sclr,
    wrreq => dstport(1)(2),
    empty => empty(6),
    full => full(6),
    q => output3_mux(17 downto 9), 
    usedw => usedw(6)
);
f8: crossbarfifo
port map (
    clock => clock,
    data => data(1), 
    rdreq => rdreq(7),
    sclr => sclr,
    wrreq => dstport(1)(3),
    empty => empty(7),
    full => full(7),
    q => output4_mux(17 downto 9), 
    usedw => usedw(7)
);
f9: crossbarfifo
port map (
    clock => clock,
    data => data(2), 
    rdreq => rdreq(8),
    sclr => sclr,
    wrreq => dstport(2)(0),
    empty => empty(8),
    full => full(8),
    q => output1_mux(26 downto 18), 
    usedw => usedw(8)
);
f10: crossbarfifo
port map (
    clock => clock,
    data => data(2), 
    rdreq => rdreq(9),
    sclr => sclr,
    wrreq => dstport(2)(1),
    empty => empty(9),
    full => full(9),
    q => output2_mux(26 downto 18), 
    usedw => usedw(9)
);
f11: crossbarfifo
port map (
    clock => clock,
    data => data(2), 
    rdreq => rdreq(10),
    sclr => sclr,
    wrreq => dstport(2)(2),
    empty => empty(10),
    full => full(10),
    q => output3_mux(26 downto 18), 
    usedw => usedw(10)
);
f12: crossbarfifo
port map (
    clock => clock,
    data => data(2), 
    rdreq => rdreq(11),
    sclr => sclr,
    wrreq => dstport(2)(3),
    empty => empty(11),
    full => full(11),
    q => output4_mux(26 downto 18), 
    usedw => usedw(11)
);
f13: crossbarfifo
port map (
    clock => clock,
    data => data(3), 
    rdreq => rdreq(12),
    sclr => sclr,
    wrreq => dstport(3)(0),
    empty => empty(12),
    full => full(12),
    q => output1_mux(35 downto 27), 
    usedw => usedw(12)
);
f14: crossbarfifo
port map (
    clock => clock,
    data => data(3), 
    rdreq => rdreq(13),
    sclr => sclr,
    wrreq => dstport(3)(1),
    empty => empty(13),
    full => full(13),
    q => output2_mux(35 downto 27), 
    usedw => usedw(13)  
);
f15: crossbarfifo
port map (
    clock => clock,
    data => data(3), 
    rdreq => rdreq(14),
    sclr => sclr,
    wrreq => dstport(3)(2),
    empty => empty(14),
    full => full(14),
    q => output3_mux(35 downto 27), 
    usedw => usedw(14)
);
f16: crossbarfifo
port map (
    clock => clock,
    data => data(3), 
    rdreq => rdreq(15),
    sclr => sclr,
    wrreq => dstport(3)(3),
    empty => empty(15),
    full => full(15),
    q => output4_mux(35 downto 27), 
    usedw => usedw(15)
);

process(clock)
    variable input_port  : integer;
    variable output_port : integer;
    variable packet_destined_here : boolean;
begin
    if rising_edge(clock) then
        if rst = '1' then
            -- Reset all state and write_enable signals
            state <= (others => '0');
            write_enable <= (others => '0');
        else
        for i in 0 to 15 loop
            -- Map the 16 FIFOs to their respective Input and Output ports
            input_port  := i / 4;   -- Yields 0, 0, 0, 0, 1, 1, 1, 1...
            output_port := i mod 4; -- Yields 0, 1, 2, 3, 0, 1, 2, 3...
            
            packet_destined_here := false;
            
            if output_port = 0 and (dstport(input_port) = "0001" or dstport(input_port) = "1110") then
                packet_destined_here := true;
            elsif output_port = 1 and (dstport(input_port) = "0010" or dstport(input_port) = "1101") then
                packet_destined_here := true;
            elsif output_port = 2 and (dstport(input_port) = "0100" or dstport(input_port) = "1011") then
                packet_destined_here := true;
            elsif output_port = 3 and (dstport(input_port) = "1000" or dstport(input_port) = "0111") then
                packet_destined_here := true;
            end if;

            case state(i) is
                when '0' =>
                    -- Check space AND check destination AND check if data is valid
                    if (4096 - to_integer(unsigned(usedw(i))) >= 1526) and packet_destined_here and rx_valid(input_port) = '1' then
                        write_enable(i) <= '1';
                        state(i) <= '1';
                    else
                        write_enable(i) <= '0';
                    end if;
                    
                when '1' =>
                    -- Keep writing until End of Packet (9th bit) is detected
                    if (data(input_port)(8) = '1') then
                        write_enable(i) <= '0'; -- Stop writing
                        state(i) <= '0';        -- Go back to looking for new packets
                    else
                        write_enable(i) <= '1'; -- Continue writing packet payload
                    end if;
                    
                when others =>
                    state(i) <= '0';
            end case;
        end loop;
        end if;
    end if;
end process;





process(clock)
    variable check_idx : integer;
    variable fifo_idx  : integer;
begin
    if rising_edge(clock) then
        if rst = '1' then
            -- Reset all state machines and outputs
            rdreq <= (others => '0');
            output1 <= (others => '0');
            output2 <= (others => '0');
            output3 <= (others => '0');
            output4 <= (others => '0');
            for i in 0 to 3 loop
                tx_state(i) <= '0';
                tx_src(i) <= 0;
                rr_turn_tx(i) <= 0;
            end loop;
        else
            -- Default all read requests to 0. We only assert them when actively locked onto a packet.
            rdreq <= (others => '0'); 
        
        -- ==========================================
        -- ARBITER FOR OUTPUT 1 (Checks FIFOs 0, 4, 8, 12)
        -- ==========================================
        case tx_state(0) is
            when '0' => -- IDLE: Look for a FIFO that has a packet ready
                
                -- Loop 4 times to check all 4 inputs in Round Robin order
                for offset in 0 to 3 loop
                    check_idx := (rr_turn_tx(0) + offset) mod 4; -- Yields 0, 1, 2, or 3
                    fifo_idx  := check_idx * 4 + 0;           -- Maps to FIFOs 0, 4, 8, 12
                    
                    if empty(fifo_idx) = '0' then 
                        tx_src(0)   <= check_idx;   -- Lock onto this input port
                        tx_state(0) <= '1';         -- Move to TRANSMIT state
                        rdreq(fifo_idx) <= '1';     -- Start popping data
                        exit;                       -- Found a packet, stop searching!
                    end if;
                end loop;
                
            when '1' => -- TRANSMITTING: Route data until End of Packet (EoP)
                
                fifo_idx := tx_src(0) * 4 + 0;
                rdreq(fifo_idx) <= '1'; -- Keep pulling data by default
                
                -- Route the correct mux to Output 1 based on who we locked onto
                if tx_src(0) = 0 then 
                    output1 <= output1_mux(7 downto 0);
                    if output1_mux(8) = '1' then            -- End of Packet Detected!
                        tx_state(0) <= '0';                 -- Go back to IDLE
                        rr_turn_tx(0)  <= 1;                   -- Pass turn to Input 2
                    end if;
                    
                elsif tx_src(0) = 1 then 
                    output1 <= output1_mux(16 downto 9);
                    if output1_mux(17) = '1' then 
                        tx_state(0) <= '0'; rr_turn_tx(0) <= 2; 
                    end if;
                    
                elsif tx_src(0) = 2 then 
                    output1 <= output1_mux(25 downto 18);
                    if output1_mux(26) = '1' then 
                        tx_state(0) <= '0'; rr_turn_tx(0) <= 3; 
                    end if;
                    
                elsif tx_src(0) = 3 then 
                    output1 <= output1_mux(34 downto 27);
                    if output1_mux(35) = '1' then 
                        tx_state(0) <= '0'; rr_turn_tx(0) <= 0; 
                    end if;
                end if;
                when others =>
                tx_state(0) <= '0';
        
        end case;

        -- ==========================================
        -- ARBITER FOR OUTPUT 2 (Checks FIFOs 1, 5, 9, 13)
        -- ==========================================

case tx_state(1) is
            when '0' => -- IDLE: Look for a FIFO that has a packet ready
                
                -- Loop 4 times to check all 4 inputs in Round Robin order
                for offset in 0 to 3 loop
                    check_idx := (rr_turn_tx(1) + offset) mod 4; -- Yields 0, 1, 2, or 3
                    fifo_idx  := check_idx * 4 + 1;           -- Maps to FIFOs 1, 5, 9, 13
                    
                    if empty(fifo_idx) = '0' then 
                        tx_src(1)   <= check_idx;   -- Lock onto this input port
                        tx_state(1) <= '1';         -- Move to TRANSMIT state
                        rdreq(fifo_idx) <= '1';     -- Start popping data
                        exit;                       -- Found a packet, stop searching!
                    end if;
                end loop;
                
            when '1' => -- TRANSMITTING: Route data until End of Packet (EoP)
                
                fifo_idx := tx_src(1) * 4 + 1;
                rdreq(fifo_idx) <= '1'; -- Keep pulling data by default
                
                -- Route the correct mux to Output 2 based on who we locked onto
                if tx_src(1) = 0 then 
                    output2 <= output2_mux(7 downto 0);
                    if output2_mux(8) = '1' then            -- End of Packet Detected!
                        tx_state(1) <= '0';                 -- Go back to IDLE
                        rr_turn_tx(1)  <= 1;                   -- Pass turn to Input 2
                    end if;
                    
                elsif tx_src(1) = 1 then 
                    output2 <= output2_mux(16 downto 9);
                    if output2_mux(17) = '1' then 
                        tx_state(1) <= '0'; rr_turn_tx(1) <= 2; 
                    end if;
                    
                elsif tx_src(1) = 2 then 
                    output2 <= output2_mux(25 downto 18);
                    if output2_mux(26) = '1' then 
                        tx_state(1) <= '0'; rr_turn_tx(1) <= 3; 
                    end if;
                    
                elsif tx_src(1) = 3 then 
                    output2 <= output2_mux(34 downto 27);
                    if output2_mux(35) = '1' then 
                        tx_state(1) <= '0'; rr_turn_tx(1) <= 0; 
                    end if;
                end if;
                when others =>
                tx_state(1) <= '0';
        end case;

        -- ==========================================
        -- ARBITER FOR OUTPUT 3 (Checks FIFOs 1, 5, 9, 13)
        -- ==========================================

        case tx_state(2) is
            when '0' => -- IDLE: Look for a FIFO that has a packet ready
                
                -- Loop 4 times to check all 4 inputs in Round Robin order
                for offset in 0 to 3 loop
                    check_idx := (rr_turn_tx(2) + offset) mod 4; -- Yields 0, 1, 2, or 3
                    fifo_idx  := check_idx * 4 + 2;           -- Maps to FIFOs 2, 6, 10, 14
                    
                    if empty(fifo_idx) = '0' then 
                        tx_src(2)   <= check_idx;   -- Lock onto this input port
                        tx_state(2) <= '1';         -- Move to TRANSMIT state
                        rdreq(fifo_idx) <= '1';     -- Start popping data
                        exit;                       -- Found a packet, stop searching!
                    end if;
                end loop;
                
            when '1' => -- TRANSMITTING: Route data until End of Packet (EoP)
                
                fifo_idx := tx_src(2) * 4 + 2;
                rdreq(fifo_idx) <= '1'; -- Keep pulling data by default
                
                -- Route the correct mux to Output 3 based on who we locked onto
                if tx_src(2) = 0 then 
                    output3 <= output3_mux(7 downto 0);
                    if output3_mux(8) = '1' then            -- End of Packet Detected!
                        tx_state(2) <= '0';                 -- Go back to IDLE
                        rr_turn_tx(2)  <= 1;                   -- Pass turn to Input 2
                    end if;
                    
                elsif tx_src(2) = 1 then 
                    output3 <= output3_mux(16 downto 9);
                    if output3_mux(17) = '1' then 
                        tx_state(2) <= '0'; rr_turn_tx(2) <= 2; 
                    end if;
                    
                elsif tx_src(2) = 2 then 
                    output3 <= output3_mux(25 downto 18);
                    if output3_mux(26) = '1' then 
                        tx_state(2) <= '0'; rr_turn_tx(2) <= 3; 
                    end if;
                elsif tx_src(2) = 3 then
                    output3 <= output3_mux(34 downto 27);
                    if output3_mux(35) = '1' then
                        tx_state(2) <= '0'; rr_turn_tx(2) <= 0;
                    end if;
                end if;
                when others =>
                tx_state(2) <= '0';
        
        end case;


        -- ==========================================
        -- ARBITER FOR OUTPUT 4 (Checks FIFOs 3, 7, 11, 15)
        -- ==========================================

        case tx_state(3) is
            when '0' => -- IDLE: Look for a FIFO that has a packet ready
                
                -- Loop 4 times to check all 4 inputs in Round Robin order
                for offset in 0 to 3 loop
                    check_idx := (rr_turn_tx(3) + offset) mod 4; -- Yields 0, 1, 2, or 3
                    fifo_idx  := check_idx * 4 + 3;           -- Maps to FIFOs 3, 7, 11, 15
                    
                    if empty(fifo_idx) = '0' then 
                        tx_src(3)   <= check_idx;   -- Lock onto this input port
                        tx_state(3) <= '1';         -- Move to TRANSMIT state
                        rdreq(fifo_idx) <= '1';     -- Start popping data
                        exit;                       -- Found a packet, stop searching!
                    end if;
                end loop;
                
            when '1' => -- TRANSMITTING: Route data until End of Packet (EoP)
                
                fifo_idx := tx_src(3) * 4 + 3;
                rdreq(fifo_idx) <= '1'; -- Keep pulling data by default
                
                -- Route the correct mux to Output 4 based on who we locked onto
                if tx_src(3) = 0 then 
                    output4 <= output4_mux(7 downto 0);
                    if output4_mux(8) = '1' then            -- End of Packet Detected!
                        tx_state(3) <= '0';                 -- Go back to IDLE
                        rr_turn_tx(3)  <= 1;                   -- Pass turn to Input 2
                    end if;
                    
                elsif tx_src(3) = 1 then 
                    output4 <= output4_mux(16 downto 9);
                    if output4_mux(17) = '1' then 
                        tx_state(3) <= '0'; rr_turn_tx(3) <= 2; 
                    end if;
                    
                elsif tx_src(3) = 2 then 
                    output4 <= output4_mux(25 downto 18);
                    if output4_mux(26) = '1' then 
                        tx_state(3) <= '0'; rr_turn_tx(3) <= 3; 
                    end if;
                elsif tx_src(3) = 3 then
                    output4 <= output4_mux(34 downto 27);
                    if output4_mux(35) = '1' then
                        tx_state(3) <= '0'; rr_turn_tx(3) <= 0;
                    end if;
                end if;

                -- ADD THESE TWO LINES:
            when others =>
                tx_state(0) <= '0';
        end case;
        
        end if;

    end if;
end process;

-- Set TX control signals based on transmission state and EOF detection
-- tx_ctrl goes low when EOF bit is detected on the output (one cycle before EOF appears externally)
tx_ctrl0 <= '1' when (tx_state(0) = '1' and output1_mux(8) = '0') else '0';
tx_ctrl1 <= '1' when (tx_state(1) = '1' and output2_mux(8) = '0') else '0';
tx_ctrl2 <= '1' when (tx_state(2) = '1' and output3_mux(8) = '0') else '0';
tx_ctrl3 <= '1' when (tx_state(3) = '1' and output4_mux(8) = '0') else '0';







END struc1;

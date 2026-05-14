LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;
LIBRARY work;
USE work.global_var.ALL;

ENTITY top_module IS
    PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;

    -- inputs 
    data_in : IN rx_in;
    data_in_valid : IN std_logic_vector(NUM_PORTS - 1 downto 0);

    -- outputs
	data_out : OUT tx_out;
	data_out_valid : OUT std_logic_vector(NUM_PORTS - 1 downto 0)
    );
END top_module;

ARCHITECTURE Behavioral OF top_module IS
	component data_input
		port(
			clk : IN STD_LOGIC;
		    rst : IN STD_LOGIC;

		    data_in : IN rx_in;
		    data_valid : IN std_logic_vector(3 downto 0);

		    data_to_crossbar : OUT crossbar_input_array;
		    dst_port : OUT crossbar_dstport_array
		);
	end component;
    
	component crossbar
		port(
			clock		: IN STD_LOGIC ;
			rst			: IN STD_LOGIC;
            data		: IN crossbar_input_array;
            dstport 	: IN crossbar_dstport_array;
            output1		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output2		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output3		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            output4		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			tx_ctrl0    : OUT STD_LOGIC;
            tx_ctrl1    : OUT STD_LOGIC;
            tx_ctrl2    : OUT STD_LOGIC;
            tx_ctrl3    : OUT STD_LOGIC;
            -- Debug ports
            debug_fifo2_wrreq : OUT STD_LOGIC;
            debug_fifo2_rdreq : OUT STD_LOGIC;
            debug_fifo2_empty : OUT STD_LOGIC;
            debug_fifo2_full : OUT STD_LOGIC;
            debug_fifo2_usedw : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
            -- Debug arbiter state signals
            debug_tx_state_1 : OUT STD_LOGIC;
            debug_tx_src_1 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            debug_rr_turn_tx_1 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
	end component;

	SIGNAL data_input_to_crossbar : crossbar_input_array := (others =>(others => '0'));
	SIGNAL dst_input_to_crossbar : crossbar_dstport_array := (others => (others => '0'));
BEGIN
	data_handling : data_input
		port map(
			clk => clk,
		    rst => rst,
		    data_in    => data_in,
		    data_valid => data_in_valid,
		    data_to_crossbar => data_input_to_crossbar,
		    dst_port 		 => dst_input_to_crossbar
		);
	cross : crossbar
		port map(
			clock	=>	clk,
			rst     =>  rst,
            data	=>	data_input_to_crossbar,
            dstport =>	dst_input_to_crossbar,
            output1	=>	data_out(0),
            output2	=>	data_out(1),
            output3	=>	data_out(2),
            output4	=>  data_out(3),
			tx_ctrl0 => data_out_valid(0),
			tx_ctrl1 => data_out_valid(1),
			tx_ctrl2 => data_out_valid(2),
			tx_ctrl3 => data_out_valid(3),
            -- Debug port
            debug_fifo2_wrreq => OPEN,
            debug_fifo2_rdreq => OPEN,
            debug_fifo2_empty => OPEN,
            debug_fifo2_full => OPEN,
            debug_fifo2_usedw => OPEN,
            -- Debug arbiter st
            debug_tx_state_1 => OPEN,
			debug_tx_src_1 => OPEN,
            debug_rr_turn_tx_1 => OPEN
		);
END Behavioral;
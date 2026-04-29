LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY RX_port IS
    PORT (
        clk : IN STD_LOGIC; -- 125 MHz system clock
        rst : IN STD_LOGIC;

        -- input
        Rx_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        Rx_ctrl : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- to FCS
        frame_length : OUT std_logic_vector(11 downto 0)
        frame_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        -- to fifo
        fifo_wren : out STD_LOGIC_vector(3 downto 0);
        fcs_error : OUT STD_LOGIC_vector(3 downto 0);
        
    );
END RX_port;

ARCHITECTURE Behavioral OF RX_port IS

    -- SIGNAL data_valid : STD_LOGIC;
    -- SIGNAL data_ready : STD_LOGIC;
    -- SIGNAL data_buffer : STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- SIGNAL ctrl_buffer : STD_LOGIC_VECTOR(3 DOWNTO 0);

    signal internal_fcs_error : STD_LOGIC_vector(3 downto 0);
    signal valid_signal : STD_LOGIC_vector(3 downto 0);

BEGIN


Rx_To_FCs_: for i in 0 to 3 generate 

valid_signal(i) <= Rx_ctrl(i);

Rx_int: entity work.fcs_parallel
    PORT MAP (
        clk => clk,
        rst => reset,

        data_in => data_in,
        valid => valid_signal(i),
        
        fcs_error => internal_fcs_error(i)

    );
END GENERATE;

fcs_error <= internal_fcs_error;

END Behavioral;
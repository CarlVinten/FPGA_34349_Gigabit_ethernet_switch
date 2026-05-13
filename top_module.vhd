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
    data_valid : IN rx_ctrl;

    -- outputs

    -- outputs to fcs check parallel
    );
END top_module;

ARCHITECTURE Behavioral OF top_module IS

BEGIN


END Behavioral;
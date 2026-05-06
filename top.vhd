library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity top_module is
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- from fcs
        fcs_error : in std_logic_vector(3 downto 0);

        -- to mac learning
        mac_src : out std_logic_vector(47 downto 0);
        mac_dst : out std_logic_vector(47 downto 0);

        -- to switch core
        data_out : out std_logic_vector(8 downto 0);
        data_ready : out std_logic_vector(3 downto 0);

    );
end top_module;

-- output 
-- 3 downto 0 
-- mac src dst valid 1 downto 0
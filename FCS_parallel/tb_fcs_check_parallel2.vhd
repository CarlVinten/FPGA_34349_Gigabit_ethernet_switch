library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fcs_check_parallel is
end entity;

architecture sim of tb_fcs_check_parallel is
    constant CLK_PERIOD : time := 8 ns;

    signal clk : std_logic := '0';
    signal reset : std_logic := '1';

    signal data_in : std_logic_vector(7 downto 0) := (others => '0');
    signal valid : std_logic := '0';

    signal is_data_valid : std_logic;

    procedure send_byte(
        signal clk_s      : in std_logic;
        signal din_s      : out std_logic_vector(7 downto 0);
        signal valid_s    : out std_logic;
        constant byte_val : in std_logic_vector(7 downto 0);
        constant valid_val: in std_logic
    ) is
    begin
        din_s <= byte_val;
        valid_s <= valid_val;
        wait until rising_edge(clk_s);
    end procedure;

begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.fcs_check_parallel
        port map (
            clk => clk,
            reset => reset,
            data_in => data_in,
            valid => valid,
            is_data_valid => is_data_valid
        );

    stim : process
    begin
        -- Reset
        reset <= '1';
        valid <= '0';
        data_in <= (others => '0');
        wait for 4 * CLK_PERIOD;
        wait until rising_edge(clk);
        reset <= '0';

        -- Send a small frame-like burst
        for i in 0 to 63 loop
            send_byte(clk, data_in, valid, std_logic_vector(to_unsigned(i, 8)), '1');
        end loop;

        -- End-of-burst by deasserting valid
        send_byte(clk, data_in, valid, x"00", '0');
        send_byte(clk, data_in, valid, x"00", '0');

        wait for 8 * CLK_PERIOD;

        -- Smoke check for resolved output state
        assert is_data_valid = '0' or is_data_valid = '1'
            report "is_data_valid is not resolved to 0/1" severity warning;

        assert false report "tb_fcs_check_parallel completed" severity note;
        wait;
    end process;

end architecture;

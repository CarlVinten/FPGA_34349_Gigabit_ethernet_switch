library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_data_input is
end entity;

architecture sim of tb_data_input is
    constant CLK_PERIOD : time := 8 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal data_in    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid : std_logic := '0';

    signal data_to_switch_core_fifo : std_logic_vector(8 downto 0);
    signal data_to_mac_fifo         : std_logic_vector(7 downto 0);
    signal data_to_ethertype        : std_logic_vector(7 downto 0);
    signal data_to_fcs              : std_logic_vector(7 downto 0);

    function has_unknown(v : std_logic_vector) return boolean is
    begin
        for i in v'range loop
            if v(i) /= '0' and v(i) /= '1' then
                return true;
            end if;
        end loop;
        return false;
    end function;

    procedure send_byte(
        signal clk_s      : in std_logic;
        signal din_s      : out std_logic_vector(7 downto 0);
        signal dvalid_s   : out std_logic;
        constant byte_val : in std_logic_vector(7 downto 0);
        constant valid_val: in std_logic
    ) is
    begin
        din_s <= byte_val;
        dvalid_s <= valid_val;
        wait until rising_edge(clk_s);
    end procedure;

begin
    clk <= not clk after CLK_PERIOD / 2;

    dut : entity work.data_input
        port map (
            clk => clk,
            rst => rst,
            data_in => data_in,
            data_valid => data_valid,
            data_to_switch_core_fifo => data_to_switch_core_fifo,
            data_to_mac_fifo => data_to_mac_fifo,
            data_to_ethertype => data_to_ethertype,
            data_to_fcs => data_to_fcs
        );

    stim : process
    begin
        -- Reset
        rst <= '1';
        data_valid <= '0';
        data_in <= (others => '0');
        wait for 4 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';

        -- Idle cycles
        send_byte(clk, data_in, data_valid, x"00", '0');
        send_byte(clk, data_in, data_valid, x"00", '0');

        -- Preamble + SOF + a short payload
        for i in 0 to 7 loop
            send_byte(clk, data_in, data_valid, x"AA", '1');
        end loop;
        send_byte(clk, data_in, data_valid, x"AB", '1');

        for i in 0 to 31 loop
            send_byte(clk, data_in, data_valid, std_logic_vector(to_unsigned(i, 8)), '1');
        end loop;

        -- End of frame indication via data_valid low
        send_byte(clk, data_in, data_valid, x"00", '0');
        send_byte(clk, data_in, data_valid, x"00", '0');

        wait for 10 * CLK_PERIOD;

        -- Smoke checks: outputs should not remain unknown forever
        assert not has_unknown(data_to_switch_core_fifo)
            report "data_to_switch_core_fifo contains unknown values" severity warning;
        assert not has_unknown(data_to_mac_fifo)
            report "data_to_mac_fifo contains unknown values" severity warning;
        assert not has_unknown(data_to_ethertype)
            report "data_to_ethertype contains unknown values" severity warning;
        assert not has_unknown(data_to_fcs)
            report "data_to_fcs contains unknown values" severity warning;

        assert false report "tb_data_input completed" severity note;
        wait;
    end process;

end architecture;

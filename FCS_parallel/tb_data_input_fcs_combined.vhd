library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_data_input_fcs_combined is
end entity;

architecture sim of tb_data_input_fcs_combined is
    constant CLK_PERIOD : time := 8 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal data_in    : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid : std_logic := '0';

    signal data_to_switch_core_fifo : std_logic_vector(8 downto 0);
    signal data_to_mac_fifo         : std_logic_vector(7 downto 0);
    signal data_to_ethertype        : std_logic_vector(7 downto 0);
    signal data_to_fcs              : std_logic_vector(7 downto 0);

    signal fcs_valid    : std_logic;
    signal is_data_valid: std_logic;

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

    -- Convert potential U/X on the valid bit into '0' for clean integration driving.
    fcs_valid <= '1' when data_to_switch_core_fifo(8) = '1' else '0';

    u_data_input : entity work.data_input
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

    u_fcs_check : entity work.fcs_check_parallel
        port map (
            clk => clk,
            reset => rst,
            data_in => data_to_fcs,
            valid => fcs_valid,
            is_data_valid => is_data_valid
        );

    stim : process
    begin
        -- Reset window
        rst <= '1';
        data_valid <= '0';
        data_in <= (others => '0');
        wait for 4 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0';

        -- Idle cycles
        send_byte(clk, data_in, data_valid, x"00", '0');
        send_byte(clk, data_in, data_valid, x"00", '0');

        -- Ethernet preamble and SFD as expected by data_input
        for i in 0 to 7 loop
            send_byte(clk, data_in, data_valid, x"AA", '1');
        end loop;
        send_byte(clk, data_in, data_valid, x"AB", '1');

        -- Destination MAC (6 bytes)
        send_byte(clk, data_in, data_valid, x"10", '1');
        send_byte(clk, data_in, data_valid, x"11", '1');
        send_byte(clk, data_in, data_valid, x"12", '1');
        send_byte(clk, data_in, data_valid, x"13", '1');
        send_byte(clk, data_in, data_valid, x"14", '1');
        send_byte(clk, data_in, data_valid, x"15", '1');

        -- Source MAC (6 bytes)
        send_byte(clk, data_in, data_valid, x"20", '1');
        send_byte(clk, data_in, data_valid, x"21", '1');
        send_byte(clk, data_in, data_valid, x"22", '1');
        send_byte(clk, data_in, data_valid, x"23", '1');
        send_byte(clk, data_in, data_valid, x"24", '1');
        send_byte(clk, data_in, data_valid, x"25", '1');

        -- EtherType (IPv4 = 0x0800)
        send_byte(clk, data_in, data_valid, x"08", '1');
        send_byte(clk, data_in, data_valid, x"00", '1');

        -- Payload bytes
        for i in 0 to 31 loop
            send_byte(clk, data_in, data_valid, std_logic_vector(to_unsigned(i, 8)), '1');
        end loop;

        -- End frame by lowering external stream valid
        send_byte(clk, data_in, data_valid, x"00", '0');
        send_byte(clk, data_in, data_valid, x"00", '0');

        wait for 20 * CLK_PERIOD;

        assert is_data_valid = '0' or is_data_valid = '1'
            report "Combined TB: is_data_valid is unresolved" severity warning;

        assert false report "tb_data_input_fcs_combined completed" severity note;
        wait;
    end process;

end architecture;

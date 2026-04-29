library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.global_var.all;

entity crossbar_tb is
end entity;

architecture tb of crossbar_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clock   : std_logic := '0';
    signal data    : crossbar_input_array := (others => (others => '0'));
    signal dstport : crossbar_dstport_array := (others => (others => '0'));
    signal output1 : std_logic_vector(8 downto 0) := (others => '0');
    signal output2 : std_logic_vector(8 downto 0) := (others => '0');
    signal output3 : std_logic_vector(8 downto 0) := (others => '0');
    signal output4 : std_logic_vector(8 downto 0) := (others => '0');

    signal stop_clock : boolean := false;

    constant ZERO_WORD : std_logic_vector(8 downto 0) := (others => '0');
    constant ZERO_PORT : std_logic_vector(3 downto 0) := "0000";
    constant PORT0     : std_logic_vector(3 downto 0) := "0001";
    constant PORT1     : std_logic_vector(3 downto 0) := "0010";
    constant PORT2     : std_logic_vector(3 downto 0) := "0100";
    constant PORT3     : std_logic_vector(3 downto 0) := "1000";
    constant BCAST     : std_logic_vector(3 downto 0) := "1111";
    constant INVALID   : std_logic_vector(3 downto 0) := "0011";

    function route_data(src : natural; dst : natural) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned((src * 4) + dst + 1, 9));
    end function;

    function select_port(dst : natural) return std_logic_vector is
    begin
        case dst is
            when 0 => return PORT0;
            when 1 => return PORT1;
            when 2 => return PORT2;
            when 3 => return PORT3;
            when others => return ZERO_PORT;
        end case;
    end function;

    procedure wait_cycles(constant cycles : in natural) is
    begin
        for index in 1 to cycles loop
            wait until rising_edge(clock);
        end loop;
    end procedure;

    procedure check_outputs(
        constant scenario : in string;
        constant expected1 : in std_logic_vector(8 downto 0);
        constant expected2 : in std_logic_vector(8 downto 0);
        constant expected3 : in std_logic_vector(8 downto 0);
        constant expected4 : in std_logic_vector(8 downto 0)
    ) is
    begin
        assert output1 = expected1
            report scenario & ": output1 mismatch"
            severity error;
        assert output2 = expected2
            report scenario & ": output2 mismatch"
            severity error;
        assert output3 = expected3
            report scenario & ": output3 mismatch"
            severity error;
        assert output4 = expected4
            report scenario & ": output4 mismatch"
            severity error;
    end procedure;

begin

    clock_driver : process
    begin
        while not stop_clock loop
            clock <= '0';
            wait for CLK_PERIOD / 2;
            exit when stop_clock;
            clock <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    dut : entity work.crossbar
        port map (
            clock   => clock,
            data    => data,
            dstport => dstport,
            output1 => output1,
            output2 => output2,
            output3 => output3,
            output4 => output4
        );

    stimulus : process
        variable expected : crossbar_input_array;
        variable next_data : crossbar_input_array;
        variable next_port : crossbar_dstport_array;
        variable selected  : std_logic_vector(8 downto 0);
    begin
        report "Starting crossbar testbench" severity note;

        next_data := (others => ZERO_WORD);
        next_port := (others => ZERO_PORT);
        data <= next_data;
        dstport <= next_port;
        wait_cycles(5);
        expected := (others => ZERO_WORD);
        check_outputs("Idle reset", expected(0), expected(1), expected(2), expected(3));

        for src in 0 to 3 loop
            for dst in 0 to 3 loop
                next_data := (others => ZERO_WORD);
                next_port := (others => ZERO_PORT);
                selected := route_data(src, dst);
                next_data(src) := selected;
                next_port(src) := select_port(dst);
                data <= next_data;
                dstport <= next_port;
                wait_cycles(5);
                expected := (others => ZERO_WORD);
                expected(dst) := selected;
                check_outputs("Unicast routing", expected(0), expected(1), expected(2), expected(3));
            end loop;
        end loop;

        next_data := (others => ZERO_WORD);
        next_port := (others => ZERO_PORT);
        next_data(0) := route_data(0, 0);
        next_port(0) := INVALID;
        next_port(1) := "0101";
        next_port(2) := "0110";
        next_port(3) := "0111";
        data <= next_data;
        dstport <= next_port;
        wait_cycles(5);
        expected := (others => ZERO_WORD);
        check_outputs("Invalid destination ports", expected(0), expected(1), expected(2), expected(3));

        next_data := (others => ZERO_WORD);
        next_port := (others => ZERO_PORT);
        next_data(0) := route_data(0, 3);
        next_port(0) := BCAST;
        data <= next_data;
        dstport <= next_port;
        wait_cycles(5);
        expected := (others => next_data(0));
        check_outputs("Broadcast from input 0", expected(0), expected(1), expected(2), expected(3));

        next_data := (others => ZERO_WORD);
        next_port := (others => ZERO_PORT);
        next_data(0) := route_data(0, 0);
        next_data(1) := route_data(1, 1);
        next_data(2) := route_data(2, 2);
        next_data(3) := route_data(3, 3);
        next_port(0) := PORT0;
        next_port(1) := PORT1;
        next_port(2) := PORT2;
        next_port(3) := PORT3;
        data <= next_data;
        dstport <= next_port;
        wait_cycles(5);
        expected(0) := next_data(0);
        expected(1) := next_data(1);
        expected(2) := next_data(2);
        expected(3) := next_data(3);
        check_outputs("Concurrent independent routes", expected(0), expected(1), expected(2), expected(3));

        report "Crossbar testbench completed" severity note;
        stop_clock <= true;
        wait for CLK_PERIOD;
        wait;
    end process;

end architecture;

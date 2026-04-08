library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

--her skal der nok stå noget om entity og architecture

entity crossbar is
    port
    (
        clock		: IN STD_LOGIC ;
        data1		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
        data2		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
        data3		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
        data4		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
        dstport1		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        dstport2		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        dstport3		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        dstport4		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
        output1		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
        output2		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
        output3		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
        output4		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
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
        usedw		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
    );
END COMPONENT;


SIGNAL output1_mux: std_logic_vector(31 downto 0);
SIGNAL output2_mux: std_logic_vector(31 downto 0);
SIGNAL output3_mux: std_logic_vector(31 downto 0);
SIGNAL output4_mux: std_logic_vector(31 downto 0);

-- signal declarations 

begin
    --port map for mem component

f1: mem
port map (
    clock => clock,
    data => data1,
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output1_mux(7 downto 0),
    usedw => usedw
);
f2: mem
port map (
    clock => clock,
    data => data1,
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output2_mux(7 downto 0),
    usedw => usedw
);
f3: mem
port map (
    clock => clock,
    data => data1,
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output3_mux(7 downto 0),
    usedw => usedw
);
f4: mem
port map (
    clock => clock,
    data => data1,
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output4_mux(7 downto 0),
    usedw => usedw
);
f5: mem
port map (
    clock => clock,
    data => data2, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output1_mux(15 downto 8), 
    usedw => usedw
);
f6: mem
port map (
    clock => clock,
    data => data2, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output2_mux(15 downto 8), 
    usedw => usedw
);
f7: mem
port map (
    clock => clock,
    data => data2, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output3_mux(15 downto 8), 
    usedw => usedw
);
f8: mem
port map (
    clock => clock,
    data => data2, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output4_mux(15 downto 8), 
    usedw => usedw
);
f9: mem
port map (
    clock => clock,
    data => data3, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output1_mux(23 downto 16), 
    usedw => usedw
);
f10: mem
port map (
    clock => clock,
    data => data3, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output2_mux(23 downto 16), 
    usedw => usedw
);
f11: mem
port map (
    clock => clock,
    data => data3, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output3_mux(23 downto 16), 
    usedw => usedw
);
f12: mem
port map (
    clock => clock,
    data => data3, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output4_mux(23 downto 16), 
    usedw => usedw
);
f13: mem
port map (
    clock => clock,
    data => data4, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output1_mux(31 downto 24), 
    usedw => usedw
);
f14: mem
port map (
    clock => clock,
    data => data4, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output2_mux(31 downto 24), 
    usedw => usedw
);
f15: mem
port map (
    clock => clock,
    data => data4, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output3_mux(31 downto 24), 
    usedw => usedw
);
f16: mem
port map (
    clock => clock,
    data => data4, 
    rdreq => rdreq,
    sclr => sclr,
    wrreq => wrreq,
    empty => empty,
    full => full,
    q => output4_mux(31 downto 24), 
    usedw => usedw
);

if out4port = 3
    output4 <= output4_mux(23 downto 16);


END struc1
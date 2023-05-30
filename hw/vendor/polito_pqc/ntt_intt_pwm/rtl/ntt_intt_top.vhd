library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ntt_intt_top is
    port(
        clk, rst: in std_logic;
        load_a_f,load_a_i : in std_logic;
        load_b_f,load_b_i: in std_logic;
        read_a,read_b: in std_logic;
        start_ab: in std_logic;
        start_fntt,start_pwm2,start_intt: in std_logic;
        din: in std_logic_vector(15 downto 0);
        dout: out std_logic_vector(15 downto 0);
        done: out std_logic
    );
end entity ntt_intt_top;

architecture RTL of ntt_intt_top is

    component ntt_intt
        port(
            clk, rst                           : in  std_logic;
            load_a_f, load_a_i                 : in  std_logic;
            load_b_f, load_b_i                 : in  std_logic;
            read_a, read_b                     : in  std_logic;
            start_ab                           : in  std_logic;
            start_fntt, start_pwm2, start_intt : in  std_logic;
            din                                : in  std_logic_vector(15 downto 0);
            dout                               : out std_logic_vector(15 downto 0);
            done                               : out std_logic
        );
    end component ntt_intt;

    signal load_a_f_R, load_a_i_R, load_b_f_R, load_b_i_R : std_logic;
    signal read_a_R, read_b_R, start_ab_R : std_logic;
    signal start_fntt_R, start_pwm2_R, start_intt_R : std_logic;
    signal din_R : std_logic_vector(15 downto 0);
    signal dout_W : std_logic_vector(15 downto 0);
    signal done_W : std_logic;

begin

    p_main : process (clk, rst)
    begin
        if rst = '1' then
            load_a_f_R <= '0';
            load_a_i_R <= '0';
            load_b_f_R <= '0';
            load_b_i_R <= '0';
            read_a_R <= '0';
            read_b_R <= '0';
            start_ab_R <= '0';
            start_fntt_R <= '0';
            start_pwm2_R <= '0';
            start_intt_R <= '0';
            din_R <= (others => '0');
            dout <= (others => '0');
            done <= '0';
        elsif clk'event and clk = '1' then
            load_a_f_R <= load_a_f;
            load_a_i_R <= load_a_i;
            load_b_f_R <= load_b_f;
            load_b_i_R <= load_b_i;
            read_a_R <= read_a;
            read_b_R <= read_b;
            start_ab_R <= start_ab;
            start_fntt_R <= start_fntt;
            start_pwm2_R <= start_pwm2;
            start_intt_R <= start_intt;
            din_R <= din;
            dout <= dout_W;
            done <= done_W;
        end if;
    end process;



    uut: ntt_intt
        port map(
            clk        => clk,
            rst        => rst,
            load_a_f   => load_a_f_R,
            load_a_i   => load_a_i_R,
            load_b_f   => load_b_f_R,
            load_b_i   => load_b_i_R,
            read_a     => read_a_R,
            read_b     => read_b_R,
            start_ab   => start_ab_R,
            start_fntt => start_fntt_R,
            start_pwm2 => start_pwm2_R,
            start_intt => start_intt_R,
            din        => din_R,
            dout       => dout_W,
            done       => done_W
        );


end architecture RTL;

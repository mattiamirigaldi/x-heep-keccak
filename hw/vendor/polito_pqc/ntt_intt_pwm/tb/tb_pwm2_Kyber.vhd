library work;
use work.param.all;

library ieee;
library std;
use std.textio.all;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

entity tb_pwm2_Kyber is
end entity tb_pwm2_Kyber;

architecture RTL of tb_pwm2_Kyber is
    
    component ntt_intt_top
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
    end component ntt_intt_top;

    signal                   clk, rst : std_logic;
    signal                   load_a_f, load_a_i : std_logic;
    signal                   load_b_f, load_b_i : std_logic;
    signal                   read_a, read_b : std_logic;
    signal                   start_ab : std_logic;
    signal                   start_fntt, start_pwm2, start_intt : std_logic;
    signal  din : std_logic_vector(15 downto 0);
    signal dout : std_logic_vector(15 downto 0);
    signal                    done_sig : std_logic;

    type din_array is array (0 to 255) of std_logic_vector(15 downto 0);

    signal din1 : din_array;
    signal din0 : din_array;
    signal doua : din_array;
    signal fout : din_array;

    type st_type is (IDLE, READ_IN_1, READ_IN_2, START, PWM2, READ_OUT, CHECK, WAIT_READ, DONE);
    signal st : st_type;

begin

    clock_driver : process
        constant period : time := 5 ns;
    begin
        clk <= '0';
        wait for period / 2;
        clk <= '1';
        wait for period / 2;
    end process clock_driver;

    rst <= '1', '0' after 100 ns;

    main_process: process(clk, rst)
        variable i, k, m, e: integer; -- @suppress "variable i is never read"
        variable temp: integer;
        variable linebuf_DIN0_MFNTT, linebuf_DIN1_MFNTT : line;
        variable linebuf_DOUT_MINTT  : line;
        variable line_out : line;
        variable dina_t : std_logic_vector(15 downto 0);
        variable dinb_t : std_logic_vector(15 downto 0);
        variable doua_t : std_logic_vector(15 downto 0);

        file filein_DIN0_MFNTT : text open read_mode is "../test/pwm_test/pwm_DIN_A1.txt";
        file filein_DIN1_MFNTT : text open read_mode is "../test/pwm_test/pwm_DIN_B1.txt";
        file filein_DOUT_MINTT : text open read_mode is "../test/pwm_test/pwm_DOUT1.txt";
        file fileout : text open write_mode is "../test/LOG/LOG_PWM.txt";
    begin
        if rst = '1' then
            st <= IDLE;
            
            load_a_f   <='0';
            load_a_i   <='0';
            load_b_f   <='0';
            load_b_i   <='0';
            read_a     <='0';
            read_b     <='0';
            start_ab   <='0';
            start_fntt <='0';
            start_pwm2 <='0';
            start_intt <='0';
            din        <= (others=>'0');
            din0 <= (others=>"0");
            din1 <= (others=>"0");
            doua <= (others=>"0");
            fout <= (others=>"0");
            m :=0;
            e :=0;
            i := 0;
            k:=0;
            temp:=0;
            
        elsif clk'event and clk = '1' then

            case st is

                when IDLE =>
        
                    load_a_f   <='0';
                    load_a_i   <='1';
                    load_b_f   <='0';
                    load_b_i   <='0';
                    read_a     <='0';
                    read_b     <='0';
                    start_ab   <='0';
                    start_fntt <='0';
                    start_pwm2 <='0';
                    start_intt <='0';
                    din        <= (others=>'0');
                    st <= READ_IN_1;
                    k :=0;
                    
                    for i in 0 to 255 loop
                        readline(filein_DIN0_MFNTT, linebuf_DIN0_MFNTT);
                        readline(filein_DIN1_MFNTT, linebuf_DIN1_MFNTT);
                        readline(filein_DOUT_MINTT, linebuf_DOUT_MINTT);

                        hread(linebuf_DIN0_MFNTT, dina_t);
                        hread(linebuf_DIN1_MFNTT, dinb_t);
                        hread(linebuf_DOUT_MINTT, doua_t);
                        --hread(linebuf_DIN1_MFNTT, doub_t);

                        din0(i) <= dina_t;
                        din1(i) <= dinb_t;
                        doua(i) <= doua_t;
                        --doub(i) <= doub_t;
                    end loop;

                when READ_IN_1 =>
                    
                    load_a_i   <='0';
                    
                    din <= din0(k);
                   
                     if k = 64 then
                            st <= READ_IN_2;
                            k :=0;
                            temp:=0;
                            load_b_i   <='1';
                        else
                            if temp=0 then
                                din <= din0(4*k+0);
                                st <= READ_IN_1;
                                temp:=temp+1;
                            elsif temp=1 then
                                din <= din0(4*k+2);
                                st <= READ_IN_1;
                                temp:=temp+1;
                            elsif temp=2 then
                                din <= din0(4*k+1);
                                st <= READ_IN_1;
                                temp:=temp+1;
                            elsif temp=3 then
                                din <= din0(4*k+3);
                                k:= k+1;
                                st <= READ_IN_1;
                                temp :=0;
                            end if;
                        end if;
                        
                when READ_IN_2 =>
                    
                    
                    load_b_i   <='0';
                    
                    din<= din1(k);
                   
                     if k = 64 then
                            st <= START;
                            k :=0;
                        else
                            if temp=0 then
                                din <= din1(4*k+0);
                                st <= READ_IN_2;
                                temp:=temp+1;
                            elsif temp=1 then
                                din <= din1(4*k+2);
                                st <= READ_IN_2;
                                temp:=temp+1;
                            elsif temp=2 then
                                din <= din1(4*k+1);
                                st <= READ_IN_2;
                                temp:=temp+1;
                            elsif temp=3 then
                                din <= din1(4*k+3);
                                k:= k+1;
                                st <= READ_IN_2;
                                temp :=0;
                            end if;
                        end if;

                when START =>
                    
                    k := k+1;
                    if k=257 then
                        start_pwm2 <= '1';
                        start_ab <='0';
                        st <= PWM2;
                    else
                        start_pwm2 <= '0';
                        start_ab <='0';
                        st <= START ;
                    end if;
                    
                     
                when PWM2 =>

                    start_pwm2 <= '0';
                    start_ab <='0';
                    if done_sig = '0' then
                        st <= PWM2;
                    else
                        st <= WAIT_READ;
                        read_a <= '1';
                        temp :=0;
                        i :=0;
                    end if;

                when WAIT_READ =>
                    read_a <= '0';
                    
                    if i=4 then
                        st <= READ_OUT;
                    else
                        st <= WAIT_READ;
                        i := i+1;
                    end if;
                
                when READ_OUT =>
                    
                        if m = 64 then
                            st <= CHECK;
                            m :=0;
                        else
                            if temp=0 then
                                fout(4*m+0) <= dout;
                                st <= READ_OUT;
                                temp:=temp+1;
                            elsif temp=1 then
                                fout(4*m+2) <= dout;
                                st <= READ_OUT;
                                temp:=temp+1;
                            elsif temp=2 then
                                fout(4*m+1) <= dout;
                                st <= READ_OUT;
                                temp:=temp+1;
                            elsif temp=3 then
                                fout(4*m+3) <= dout;
                                m:= m+1;
                                st <= READ_OUT;
                                temp :=0;
                            end if;
                        end if;

                when CHECK =>
                    if m = 255 then
                        st <= DONE;
                        m :=0;
                    else
                        if fout(m) = doua(m) then
                            e := e+1;
                            write(line_out,"Right result -- index:" & integer'image(m) & ", result: 0x" & to_hstring(doua(m)));
                        else
                            write(line_out, "Wrong result -- index:" & integer'image(m) & ", expected: 0x" & to_hstring(doua(m)) & "--> calculated:0x" & to_hstring(fout(m)));
                            report ("Wrong result -- index:" & integer'image(m) & ", expected: 0x" & to_hstring(doua(m))) & "--> calculated:0x" & to_hstring(fout(m));
                        end if;
                        m := m+1;
                        writeline(fileout,line_out);
                    end if;
                    
                when DONE => -- @suppress "Dead state 'DONE': state does not have outgoing transitions"
                    
                    if e=255 then
                        report ("PWM2 -- Correct!");
                    else
                        report ("PWM2 -- Incorrect!");
                    end if;
                    
                    
                    FILE_CLOSE(filein_DIN0_MFNTT);
                    FILE_CLOSE(filein_DIN1_MFNTT);
                    FILE_CLOSE(filein_DIN0_MFNTT);
                    FILE_CLOSE(fileout);
                    assert false report "Simulation completed" severity failure;

            end case;
        end if;


    end process;


    uut: ntt_intt_top
        port map(
            clk        => clk,
            rst        => rst,
            load_a_f   => load_a_f,
            load_a_i   => load_a_i,
            load_b_f   => load_b_f,
            load_b_i   => load_b_i,
            read_a     => read_a,
            read_b     => read_b,
            start_ab   => start_ab,
            start_fntt => start_fntt,
            start_pwm2 => start_pwm2,
            start_intt => start_intt,
            din        => din,
            dout       => dout,
            done       => done_sig
        );






end architecture RTL;

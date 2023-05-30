library work;
use work.param.all;

library ieee;
library std;
use std.textio.all;

use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

entity tb_ntt_Kyber is
end entity tb_ntt_Kyber;

architecture RTL of tb_ntt_Kyber is
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
    type dout_array is array (0 to 255) of signed(15 downto 0);

    signal dina : din_array;
    signal dinb : din_array;
    signal doua : din_array;
    signal doub : din_array;
    signal fout : din_array;

    type st_type is (IDLE, READ_IN, START, FNTT, READ_OUT, CHECK, WAIT_READ, DONE);
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
        variable temp_din: signed(15 downto 0);
        variable linebuf_DIN0, linebuf_DIN0_MFNTT : line;
        variable line_out : line;
        variable dina_t : std_logic_vector(15 downto 0);
        variable doua_t : std_logic_vector(15 downto 0);


        file filein_DIN0 : text open read_mode is "../test/ntt_test/ntt_DIN1.txt";
        file filein_DIN0_MFNTT : text open read_mode is "../test/ntt_test/ntt_DOUT1.txt";
        file fileout : text open write_mode is "../test/LOG/LOG_NTT.txt";
        
        

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
            dina <= (others=>"0");
            --dinb <= (others=>"0");
            doua <= (others=>"0");
            --doub <= (others=>"0");
            fout <= (others=>"0");
            m :=0;
            e :=0;
            i := 0;
            
        elsif clk'event and clk = '1' then

            case st is

                when IDLE =>
        
                    load_a_f   <='1';
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
                    st <= READ_IN;
                    k :=0;
                    
                    for i in 0 to 255 loop
                        readline(filein_DIN0, linebuf_DIN0);
                        readline(filein_DIN0_MFNTT, linebuf_DIN0_MFNTT);

                        hread(linebuf_DIN0, dina_t);
                        hread(linebuf_DIN0_MFNTT, doua_t);


                        dina(i) <= dina_t;
                        doua(i) <= doua_t;
    
                    
                    end loop;

                when READ_IN =>
                    
                    load_a_f   <='0';
                    din <= dina(k);
                   
                    if k=255 then
                        st <= START;
                    else
                        k := k+1;
                        st <= READ_IN;
                    end if;

                when START =>
                    
                    k := k+1;
                    if k=257 then
                        start_fntt <= '1';
                        start_ab <='0';
                        st <= FNTT;
                    else
                        start_fntt <= '0';
                        start_ab <='0';
                        st <= START ;
                    end if;
                    
                     
                when FNTT =>

                    start_fntt <= '0';
                    start_ab <='0';
                    if done_sig = '0' then
                        st <= FNTT;
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
                        if signed(fout(m)) = signed(doua(m)) then
                            e := e+1;
                            write(line_out,"Right result -- index:" & integer'image(m) & ", result: 0x" & to_hstring(doua(m)));
                        else
                            write(line_out, "Wrong result -- index:" & integer'image(m) & ", expected: 0x" & to_hstring(doua(m)) & "--> calculated:0x" & to_hstring(fout(m)));
                            report ("Wrong result -- index:" & integer'image(m) & ", expected: 0x" & to_hstring(doua(m)) & "--> calculated:0x" & to_hstring(fout(m)));
                        end if;
                        m := m+1;
                        writeline(fileout,line_out);
                    end if;
                    
                when DONE => -- @suppress "Dead state 'DONE': state does not have outgoing transitions"
                    
                    if e=255 then
                        report ("NTT1 -- Correct!");
                    else
                        report ("NTT1 -- Incorrect!");
                    end if;
                    
                    
                    FILE_CLOSE(filein_DIN0);
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

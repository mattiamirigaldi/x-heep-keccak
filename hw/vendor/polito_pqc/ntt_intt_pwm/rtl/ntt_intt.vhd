library work;
use work.param.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ntt_intt is
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
end entity ntt_intt;

architecture RTL of ntt_intt is


    --------------COMPONENT------------------------------------------------
    component BRAM
        port(
            clk   : in  std_logic;
            wen   : in  std_logic;
            waddr : in  std_logic_vector(7 downto 0);
            din   : in  std_logic_vector(15 downto 0);
            raddr : in  std_logic_vector(7 downto 0);
            dout  : out std_logic_vector(15 downto 0)
        );
    end component BRAM;
    
    component BROM_TW
        port(
            clk   : in  std_logic;
            raddr : in  std_logic_vector(8 downto 0);
            dout  : out std_logic_vector(15 downto 0)
        );
    end component BROM_TW;
    
    component address_generator
        port(
            rst, clk                           : in  std_logic;
            start_fntt, start_pwm2, start_intt : in  std_logic;
            CT                                 : out std_logic;
            PWM                                : out std_logic;
            raddr0, raddr1                     : out std_logic_vector(7 downto 0);
            waddr0, waddr1                     : out std_logic_vector(7 downto 0);
            wen0, wen1                         : out std_logic;
            brsel0, brsel1                     : out std_logic;
            brselen0, brselen1                 : out std_logic;
            stage_count                        : out std_logic_vector(2 downto 0);
            stage_count_pwm                    : out std_logic_vector(2 downto 0);
            c_loop_pwm                         : out std_logic_vector(6 downto 0);
            raddr_b                            : out std_logic_vector(6 downto 0);
            raddr_tw                           : out std_logic_vector(8 downto 0)
        );
    end component address_generator;
    
    component butterfly
        port(
            clk, rst       : in  std_logic;
            CT, PWM        : in  std_logic;
            OP_SEL         : in  std_logic;
            A, B, W        : in  std_logic_vector(15 downto 0);
            E, O           : out std_logic_vector(15 downto 0);
            MUL            : out std_logic_vector(15 downto 0);
            ADD, SUB       : out std_logic_vector(15 downto 0)
        );
    end component butterfly;
    
    component barrett
        port(
            barrett_din  : in  std_logic_vector(15 downto 0);
            barrett_dout : out std_logic_vector(15 downto 0)
        );
    end component barrett;
    
    component modmul
        port(
            clk, rst             : in  std_logic;
            mod_mul_sel          : in  std_logic;
            mod_mul_A, mod_mul_B : in  std_logic_vector(15 downto 0);
            mod_mul_out          : out std_logic_vector(15 downto 0)
        );
    end component modmul;
    
    component bN_2to1mux
        generic(N : positive := 8);
        port(
            x, y   : in  std_logic_vector(N-1 downto 0);
            s      : in  std_logic;
            output : out std_logic_vector(N-1 downto 0)
        );
    end component bN_2to1mux;



    -------------SIGNALS---------------------------------------------------
    TYPE state IS (IDLE, LOAD, FNTT, INTT, PWM2, READ);
    signal y: state;

    signal din_cnt : unsigned(7 downto 0);    --counter for OP_LOAD_DATA/B state
    signal dout_cnt : unsigned(8 downto 0);    --counter for OP_READ_DATA/B state
    signal op_cnt : unsigned(9 downto 0);    --counter for FNTT,INTT,PWM2 operations

    signal op_out_a, op_out_b : std_logic;
    
    signal op_selector : std_logic;

    signal load_type : std_logic;           --0 for FNTT, 1 for INTT
    signal load_ab, read_ab, exec_ab : std_logic; --0 for A, 1 for B

    --bram signals for input polynomial: 0,1 
    --signals before going to brams
    signal di0_0, di0_1, di1_0, di1_1, di2_0, di2_1 : std_logic_vector(15 downto 0);
    signal do0_0, do0_1, do1_0, do1_1 : std_logic_vector(15 downto 0);
    signal dw0_0, dw0_1, dw1_0, dw1_1, dw2_0, dw2_1 : std_logic_vector(7 downto 0);
    signal dr0_0, dr0_1, dr1_0, dr1_1, dr2_0, dr2_1 : std_logic_vector(7 downto 0);
    signal de0_0, de0_1, de1_0, de1_1, de2_0, de2_1 : std_logic;

    --bram signals for twiddle factors
    signal t_o, t_o_ca2, t_o_mux1_out : std_logic_vector(15 downto 0);
    signal t_r : std_logic_vector(8 downto 0);
    signal t_o_temp: std_logic_vector(15 downto 0);

    --control unit signals (from control unit to top module)
    signal c_ct, c_pwm : std_logic;
    signal raddr0, raddr1, waddr0, waddr1 : std_logic_vector(7 downto 0);
    signal wen0, wen1, brsel0, brsel1, brselen0, brselen1 : std_logic;
    signal stage_cnt, stage_cnt_pwm : std_logic_vector(2 downto 0);
    signal c_loop_pwm : std_logic_vector(6 downto 0);
    signal raddr_b : std_logic_vector(6 downto 0);
    signal raddr_tw : std_logic_vector(8 downto 0);
    signal raddr_tw_ca2: std_logic;
    
    --signals for barrett module
    signal barrett_out0, barrett_out1, barrett_mux_out, barrett_out: std_logic_vector(15 downto 0);
    --signals for montgomery module
    signal MONT_std, montgomery_out: std_logic_vector(15 downto 0);
    signal dout_reduced, final_dout: std_logic_vector(15 downto 0);
    --signals for PU blocks
    signal CT, PWM : std_logic;
    signal PWM_TW, sel_PWM_TW : std_logic;
    signal A, B, W : std_logic_vector(15 downto 0);
    signal E, O, MUL, ADD, SUB : std_logic_vector(15 downto 0); -- @suppress "signal ADD is never read" -- @suppress "signal SUB is never read"

begin


    --FSM----------------------------------------------------------------
    ntt_intt_FSM: process (clk, rst)
    begin  -- process
        if rst = '1' then -- asynchronous reset (active high)

            y <= IDLE;
            PWM_TW <= '0';

        elsif clk'event and clk = '1' then  -- rising clock edge
            case y is
                when IDLE =>
                    if load_a_f = '1' or load_a_i = '1' or load_b_f = '1' or load_b_i = '1' then
                        y <= LOAD;
                    elsif start_fntt = '1' then
                        y <= FNTT;
                    elsif start_pwm2 = '1' then
                        y <= PWM2;
                        PWM_TW <= '1';
                    elsif start_intt = '1' then
                        y <= INTT;
                    elsif read_a = '1' or read_b = '1' then
                        y <= READ;
                    else
                        y <= IDLE;
                    end if;
                when LOAD =>
                    if din_cnt = 255 then
                        y <= IDLE;
                    else
                        y <= LOAD;
                    end if;
                when FNTT =>
                    if op_cnt = FNTT_CC-1 then
                        y <= IDLE;
                    else
                        y <= FNTT;
                    end if;
                    op_selector <= '1';
                when INTT =>
                    if op_cnt = INTT_CC-1 then
                        y <= IDLE;
                    else
                        y <= INTT;
                    end if;
                    op_selector <= '0';
                when PWM2 =>
                    if op_cnt = PWM2_CC-1 then
                        y <= IDLE;
                    else
                        y <= PWM2;
                    end if;
                    op_selector <= '1';
                when READ =>
                    if dout_cnt = 257 then
                        y <= IDLE;
                    else
                        y <= READ;
                    end if;
            end case;
        end if;

    end process;

    ---ntt_intt processes----------------------------------------------------------
    ntt_intt_1: process (clk, rst)
    begin
        if (rst = '1') then
            load_type <= '0';
        elsif clk'event and clk = '1' then
            if load_a_i = '1' or load_b_i = '1' then
                load_type <= '1';
            elsif y = LOAD then
                load_type <= load_type;
            else
                load_type <= '0';
            end if;
        end if;
    end process;

    ntt_intt_2: process (clk, rst)
    begin
        if (rst = '1') then
            op_out_a <= '0';
        elsif clk'event and clk = '1' then
            if start_fntt = '1' and start_ab = '0' then
                op_out_a <= '1'; --Doing FNTT (output will be at address 1)
            elsif start_pwm2 = '1' and start_ab = '0' then
                op_out_a <= '1'; --Doing PWM2 (output will be at address 1)
            elsif start_intt = '1' and start_ab = '0' then
                op_out_a <= '0'; --Doing INTT (output will be at address 0)
            else
                op_out_b <= op_out_b;
            end if;
        end if;
    end process;

    ntt_intt_3: process (clk, rst)
    begin
        if (rst = '1') then
            op_out_b <= '0';
        elsif clk'event and clk = '1' then
            if start_fntt = '1' and start_ab = '1' then
                op_out_b <= '1'; --Doing FNTT (output will be at address 1)
            elsif start_pwm2 = '1' and start_ab = '1' then
                op_out_b <= '1'; --Doing PWM2 (output will be at address 1)
            elsif start_intt = '1' and start_ab = '1' then
                op_out_b <= '0'; --Doing INTT (output will be at address 0)
            else
                op_out_b <= op_out_b;
            end if;
        end if;
    end process;

    ntt_intt_4: process (clk, rst)
    begin
        if (rst = '1') then
            load_ab <= '0';
            read_ab <= '0';
            exec_ab <= '0';
        elsif clk'event and clk = '1' then
            --load
            if(load_a_f='1' or load_a_i='1' ) then
                load_ab <= '0';
            elsif(load_b_f='1'  or load_b_i='1' ) then
                load_ab <= '1';
            elsif(y = IDLE) then
                load_ab <= '0';
            else
                load_ab <= load_ab;
            end if;
            --read
            if(read_a='1') then
                read_ab <= '0';
            elsif(read_b = '1') then
                read_ab <= '1';
            elsif(y = IDLE) then
                read_ab <= '0';
            else
                read_ab <= read_ab;
            end if;
            --exec
            if(start_fntt='1' or start_pwm2='1' or start_intt='1') then
                exec_ab <= start_ab;
            elsif(y = IDLE) then
                exec_ab <= '0';
            else
                exec_ab <= exec_ab;
            end if;
        end if;

    end process;

    ntt_intt_5: process (clk, rst)
    begin
        if (rst = '1') then
            din_cnt <= (others=>'0');
            dout_cnt <= (others=>'0');
            op_cnt <= (others=>'0');
        elsif clk'event and clk = '1' then
            if y = LOAD then
                if din_cnt=255 then
                    din_cnt <= (others=>'0');
                else
                    din_cnt <= din_cnt + 1;
                end if;
            end if;
            if y = READ then
                if dout_cnt=257 then
                    dout_cnt <= (others=>'0');
                else
                    dout_cnt <= dout_cnt + 1;
                end if;
            end if;

            case y is
                when FNTT =>
                    if op_cnt=FNTT_CC-1 then
                        op_cnt <= (others=>'0');
                    else
                        op_cnt <= op_cnt + 1;
                    end if;
                when PWM2 =>
                    if op_cnt=PWM2_CC-1 then
                        op_cnt <= (others=>'0');
                    else
                        op_cnt <= op_cnt + 1;
                    end if;
                when INTT =>
                    if op_cnt=INTT_CC-1 then
                        op_cnt <= (others=>'0');
                    else
                        op_cnt <= op_cnt + 1;
                    end if;
                when others =>
                    op_cnt <= op_cnt;
            end case;

        end if;
    end process;

    ntt_intt_6: process (clk, rst)
    begin
        if (rst = '1') then
            t_r <= (others=>'0');
        elsif clk'event and clk = '1' then
            t_r <= raddr_tw;
        end if;
    end process;

    ntt_intt_7: process( E, O, brsel0, brsel1, brselen0, brselen1, c_loop_pwm(0), din, din_cnt(0), din_cnt(6 downto 0), din_cnt(7 downto 1), din_cnt(7), dout_cnt(7 downto 1), load_type, op_out_a, op_out_b, raddr0, raddr1, read_ab, stage_cnt, waddr0, waddr1, wen0, wen1, y)
    begin
        case y is
            when LOAD =>
                di2_0 <= din;
                di2_1 <= din;

                if load_type = '0' then
                    dw2_0 <= "0" & std_logic_vector(din_cnt(6 downto 0));
                    dw2_1 <= "0" &  std_logic_vector(din_cnt(6 downto 0));
                else
                    dw2_0 <= "1" &  std_logic_vector(din_cnt(7 downto 1));
                    dw2_1 <= "1" &  std_logic_vector(din_cnt(7 downto 1));
                end if;

                dr2_0 <= (others=>'0');
                dr2_1 <= (others=>'0');
                
                 if load_type = '0' then
                    de2_0 <= not(din_cnt(7));
                    de2_1 <= din_cnt(7) ;
                else
                    de2_0 <= not(din_cnt(0));
                    de2_1 <= din_cnt(0) ;    
                end if;

            when FNTT =>
                dr2_0 <= raddr0;
                dr2_1 <= raddr1;

                if stage_cnt="000" or stage_cnt="001" or stage_cnt="010" or stage_cnt="011" or stage_cnt="100" or stage_cnt="101" then

                    if brselen0 = '1' then
                        if brsel0 = '0' then
                            di2_0 <= E;
                            dw2_0 <= waddr0;
                            de2_0 <= wen0;
                        else
                            di2_0 <= O;
                            dw2_0 <= waddr1;
                            de2_0 <= wen1;
                        end if;
                    else
                        di2_0 <= (others=>'0');
                        dw2_0 <= (others=>'0');
                        de2_0 <= '0';
                    end if;

                    if brselen1 = '1' then
                        if brsel1 = '0' then
                            di2_1 <= E;
                            dw2_1 <= waddr0;
                            de2_1 <= wen0;
                        else
                            di2_1 <= O;
                            dw2_1 <= waddr1;
                            de2_1 <= wen1;
                        end if;
                    else
                        di2_1 <= (others=>'0');
                        dw2_1 <= (others=>'0');
                        de2_1 <= '0';
                    end if;

                elsif stage_cnt="110" then
                    di2_0 <= E;
                    di2_1 <= O;
                    dw2_0 <= waddr0;
                    dw2_1 <= waddr1;
                    de2_0 <= wen0;
                    de2_1 <= wen1;
                else
                    di2_0 <= (others=>'0');
                    di2_1 <= (others=>'0');
                    dw2_0 <= (others=>'0');
                    dw2_1 <= (others=>'0');
                    de2_0 <= '0';
                    de2_1 <= '0';
                end if;


            when PWM2 =>
                if c_loop_pwm(0) = '1' then
                    --write to first BRAM
                    di2_0 <= E;
                    di2_1 <= E;
                    dw2_0 <= waddr1;
                    dw2_1 <= waddr1;
                    dr2_0 <= raddr1;
                    dr2_1 <= raddr0;
                    de2_0 <= wen1 or wen0;
                    de2_1 <= '0';
                else
                    --write to second BRAM
                    di2_0 <= E;
                    di2_1 <= E;
                    dw2_0 <= waddr1;
                    dw2_1 <= waddr1;
                    dr2_0 <= raddr1;
                    dr2_1 <= raddr0;
                    de2_0 <= '0';
                    de2_1 <= wen1 or wen0;
                end if;

            when INTT =>
                dr2_0 <= raddr0;
                dr2_1 <= raddr1;

                if stage_cnt="110" then
                    di2_0 <= E;
                    di2_1 <= O;
                    dw2_0 <= waddr0;
                    dw2_1 <= waddr1;
                    de2_0 <= wen0;
                    de2_1 <= wen1;
                else
                    if brselen0 = '1' then
                        if brsel0 = '0' then
                            di2_0 <= E;
                            dw2_0 <= waddr0;
                            de2_0 <= wen0;
                        else
                            di2_0 <= O;
                            dw2_0 <= waddr1;
                            de2_0 <= wen1;
                        end if;
                    else
                        di2_0 <= (others=>'0');
                        dw2_0 <= (others=>'0');
                        de2_0 <= '0';
                    end if;

                    if brselen1 = '1' then
                        if brsel1 = '0' then
                            di2_1 <= E;
                            dw2_1 <= waddr0;
                            de2_1 <= wen0;
                        else
                            di2_1 <= O;
                            dw2_1 <= waddr1;
                            de2_1 <= wen1;
                        end if;
                    else
                        di2_1 <= (others=>'0');
                        dw2_1 <= (others=>'0');
                        de2_1 <= '0';
                    end if;
                end if;

            when READ =>
                di2_0 <= (others=>'0');
                di2_1 <= (others=>'0');
                dw2_0 <= (others=>'0');
                dw2_1 <= (others=>'0');
                if read_ab = '0' then
                    dr2_0 <= op_out_a & std_logic_vector(dout_cnt(7 downto 1));
                    dr2_1 <= op_out_a & std_logic_vector(dout_cnt(7 downto 1));
                else
                    dr2_0 <= op_out_b & std_logic_vector(dout_cnt(7 downto 1));
                    dr2_1 <= op_out_b & std_logic_vector(dout_cnt(7 downto 1));
                end if;

                de2_0 <= '0';
                de2_1 <= '0';
            when others =>
                di2_0 <= (others=>'0');
                di2_1 <= (others=>'0');
                dw2_0 <= (others=>'0');
                dw2_1 <= (others=>'0');

                dr2_0 <= (others=>'0');
                dr2_1 <= (others=>'0');

                de2_0 <= '0';
                de2_1 <= '0';
        end case;
    end process;

    --read
    dr0_0 <= dr2_0;
    dr0_1 <= dr2_1;

    ntt_intt8: process(load_ab, read_ab, exec_ab, de2_0, de2_1, dr2_0, dr2_1, raddr_b, y)
    begin
        if y=PWM2 then
            dr1_0 <= '1' & raddr_b;
            dr1_1 <= '1' & raddr_b;
        else
            dr1_0 <= dr2_0;
            dr1_1 <= dr2_1;
        end if;

        if load_ab='1' or read_ab='1' or exec_ab ='1' then
            de0_0 <='0';
            de0_1 <= '0';
            de1_0 <= de2_0;
            de1_1 <= de2_1;
        else
            de0_0 <= de2_0;
            de0_1 <= de2_1;
            de1_0 <='0';
            de1_1 <= '0';
        end if;
    end process;

    --write
    dw0_0 <= dw2_0;
    dw0_1 <= dw2_1;
    dw1_0 <= dw2_0;
    dw1_1 <= dw2_1;

    --input
    di0_0 <= di2_0;
    di0_1 <= di2_1;
    di1_0 <= di2_0;
    di1_1 <= di2_1;

    ntt_intt9: process(clk, rst)
    begin
        if (rst = '1') then
            A   <= (others=>'0');
            B   <= (others=>'0');
            W   <= (others=>'0');
            CT  <= '0';
            PWM <= '0';
        elsif clk'event and clk = '1' then
            if y=FNTT or y=INTT then
                if exec_ab='0' then
                    A <= do0_0;
                    B <= do0_1;
                else
                    A <= do1_0;
                    B <= do1_1;
                end if;
                W <= t_o;
                CT <= c_ct;
                PWM <= c_pwm;

            elsif y=PWM2 then
                case stage_cnt_pwm is
                    when "000" =>
                        A   <= (others=>'0');
                        if c_loop_pwm(0)='0' then
                            B <= do0_0;
                            W <= do1_0;
                        else
                            B <= do0_1;
                            W <= do1_1;
                        end if;
                    when "001" =>
                        A   <= (others=>'0');
                        if c_loop_pwm(0)='0' then
                            B <= do0_0;
                            W <= do1_0;
                        else
                            B <= do0_1;
                            W <= do1_1;
                        end if;
                    when "010" =>
                        A   <= (others=>'0');
                        if c_loop_pwm(0)='0' then
                            B <= do0_0;
                            W <= do1_0;
                        else
                            B <= do0_1;
                            W <= do1_1;
                        end if;
                    when "011" =>
                        A   <= MUL;
                        if c_loop_pwm(0)='0' then
                            B <= do0_0;
                            W <= do1_0;
                        else
                            B <= do0_1;
                            W <= do1_1;
                        end if;
                    when "100" =>
                        A   <= (others=>'0');
                        B <= MUL;
                        W <= t_o;
                    when others =>
                        A   <= (others=>'0');
                        B <= (others=>'0');
                        W <= (others=>'0');
                end case;
                CT <= c_ct;
                PWM <= c_pwm;
            else
                A   <= A;
                B   <= B;
                W   <= W;
                CT  <= CT;
                PWM <= PWM;
            end if;
        end if;
    end process;
    
    ntt_intt_10: process (clk, rst)
    begin
        if (rst = '1') then
            done <= '0';
        elsif clk'event and clk = '1' then
            case y is
                when FNTT =>
                    if op_cnt = FNTT_CC-1 then
                        done <= '1';
                    else
                        done <= '0';
                    end if;
                when PWM2 =>
                    if op_cnt = PWM2_CC-1 then
                        done <= '1';
                    else
                        done <= '0';
                    end if;
                when INTT =>
                    if op_cnt = INTT_CC-1 then
                        done <= '1';
                    else
                        done <= '0';
                    end if;
                when others =>
                    done <='0';
            end case;
        end if;
    end process;
    
    barret_mux_readab0: bN_2to1mux
        generic map(
            N => 16
        )
        port map(
            x      => do0_0,
            y      => do1_0,
            s      => read_ab,
            output => barrett_out0
        );
    
    barret_mux_readab1: bN_2to1mux
        generic map(
            N => 16
        )
        port map(
            x      => do0_1,
            y      => do1_1,
            s      => read_ab,
            output => barrett_out1
        ); 
    
    barrett_mux: bN_2to1mux
        generic map(
            N => 16
        )
        port map(
            x      => barrett_out1,
            y      => barrett_out0,
            s      => dout_cnt(0),
            output => barrett_mux_out
        );
    
    
    barrett_module: barrett
        port map(
            barrett_din  => barrett_mux_out,
            barrett_dout => barrett_out
        );
        
    MONT_std <= std_logic_vector(to_signed(MONT, 16));
   
    modmul_module: modmul
        port map(
            clk         => clk,
            rst         => rst,
            mod_mul_sel => '0',
            mod_mul_A   => barrett_mux_out,
            mod_mul_B   => MONT_std,
            mod_mul_out => montgomery_out
        );
    
    mux_dout_reduced: bN_2to1mux
        generic map(
            N => 16
        )
        port map(
            x      => montgomery_out,
            y      => barrett_out,
            s      => CT,
            output => dout_reduced
        );
        
    mux_pwm_nttintt: bN_2to1mux
        generic map(
            N => 16
        )
        port map(
            x      => dout_reduced,
            y      => barrett_mux_out,
            s      => PWM_TW,
            output => final_dout
        );
    
    
    
   ntt_intt_11: process (clk, rst)
    begin
        if (rst = '1') then
            dout <= (others=>'0');
        elsif clk'event and clk = '1' then
            if y=READ then
                if dout_cnt > 0 then
                    dout <= final_dout;       
                end if;
            else
                dout <= (others=>'0'); 
            end if;
        end if;
    end process;
    
    
       
    --------instantiations----------------------------------------------------------
    ntt_intt_ag: address_generator
        port map(
            rst             => rst,
            clk             => clk,
            start_fntt      => start_fntt,
            start_pwm2      => start_pwm2,
            start_intt      => start_intt,
            CT              => c_ct,
            PWM             => c_pwm,
            raddr0          => raddr0,
            raddr1          => raddr1,
            waddr0          => waddr0,
            waddr1          => waddr1,
            wen0            => wen0,
            wen1            => wen1,
            brsel0          => brsel0,
            brsel1          => brsel1,
            brselen0        => brselen0,
            brselen1        => brselen1,
            stage_count     => stage_cnt,
            stage_count_pwm => stage_cnt_pwm,
            c_loop_pwm      => c_loop_pwm,
            raddr_b         => raddr_b,
            raddr_tw        => raddr_tw
        );
    
    b_ram0_0: BRAM
        port map(
            clk   => clk,
            wen   => de0_0,
            waddr => dw0_0,
            din   => di0_0,
            raddr => dr0_0,
            dout  => do0_0
        );

    b_ram0_1: BRAM
        port map(
            clk   => clk,
            wen   => de0_1,
            waddr => dw0_1,
            din   => di0_1,
            raddr => dr0_1,
            dout  => do0_1
        );

    b_ram1_0: BRAM
        port map(
            clk   => clk,
            wen   => de1_0,
            waddr => dw1_0,
            din   => di1_0,
            raddr => dr1_0,
            dout  => do1_0
        );

    b_ram1_1: BRAM
        port map(
            clk   => clk,
            wen   => de1_1,
            waddr => dw1_1,
            din   => di1_1,
            raddr => dr1_1,
            dout  => do1_1
        );


    b_rom: BROM_TW
        port map(
            clk   => clk,
            raddr => t_r(8 downto 0), 
            dout  => t_o
        );


    ntt_intt_bu: butterfly
        port map(
            clk => clk,
            rst => rst,
            CT  => CT,
            PWM => PWM,
            OP_SEL => op_selector,
            A   => A,
            B   => B,
            W   => W,
            E   => E,
            O   => O,
            MUL => MUL,
            ADD => ADD,
            SUB => SUB
        );
    

end architecture RTL;

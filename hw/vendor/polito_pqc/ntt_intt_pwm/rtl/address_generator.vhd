library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity address_generator is
    port(
        rst, clk : in  std_logic;
        start_fntt,start_pwm2,start_intt  : in  std_logic;
        CT   : out std_logic;
        PWM : out std_logic;
        raddr0, raddr1:  out std_logic_vector(7 downto 0);
        waddr0, waddr1 : out std_logic_vector(7 downto 0);
        wen0, wen1 : out std_logic;
        brsel0,brsel1: out std_logic;
        brselen0, brselen1 : out std_logic;
        stage_count : out std_logic_vector(2 downto 0);
        stage_count_pwm : out std_logic_vector(2 downto 0);
        c_loop_pwm : out std_logic_vector(6 downto 0);
        raddr_b : out std_logic_vector(6 downto 0);
        raddr_tw : out std_logic_vector(8 downto 0)
    );
end entity address_generator;

architecture behaviour of address_generator is

    component reg_rst
        generic(N : positive := 32);
        port(
            D   : in  std_logic_vector(N - 1 downto 0);
            rst : in  std_logic;
            clk : in  std_logic;
            Q   : out std_logic_vector(N - 1 downto 0)
        );
    end component reg_rst;


    component shiftreg
        generic(
            SHIFT : positive := 1;
            N     : positive := 32
        );
        port(
            shiftreg_in  : in  std_logic_vector(N - 1 downto 0);
            rst          : in  std_logic;
            clk          : in  std_logic;
            shiftreg_out : out std_logic_vector(N - 1 downto 0)
        );
    end component shiftreg;

    TYPE state IS (IDLE, FNTT, INTT, PWM2);
    SIGNAL y: state;

    signal c_stage, c_pwm : std_logic_vector(2 downto 0);
    signal c_loop: std_logic_vector(6 downto 0);
    signal c_tw : std_logic_vector(8 downto 0);

    signal raddr, waddre, waddro: std_logic_vector(7 downto 0);
    signal wen, brsel, brselen: std_logic_vector(0 downto 0);

    signal raddr_b_w : std_logic_vector(6 downto 0);

    signal ctd0 : std_logic_vector(0 downto 0);
    signal pwmd0: std_logic_vector(0 downto 0);
    signal waddrd0: std_logic_vector(7 downto 0);
    signal waddrd1: std_logic_vector(7 downto 0);
    signal wend0 : std_logic_vector(0 downto 0);
    signal wend1 : std_logic_vector(0 downto 0);
    signal brseld0 : std_logic_vector(0 downto 0);
    signal brseld1 : std_logic_vector(0 downto 0);
    signal brselend0 : std_logic_vector(0 downto 0);
    signal brselend1 : std_logic_vector(0 downto 0);
    signal stage_countd0 : std_logic_vector(2 downto 0);
    signal stage_count_pwmd0: std_logic_vector(2 downto 0);
    signal c_loop_pwmd0 : std_logic_vector(6 downto 0);
    signal raddr_b_wd0 : std_logic_vector(6 downto 0);
    signal raddr_twd0: std_logic_vector(8 downto 0);
    signal b_ct : std_logic_vector(0 downto 0);
    signal b_pwm : std_logic_vector(0 downto 0);

begin



    --**********************************************************************************************************---        
    ------------------------------------------------------FSM--------------------------------------------
    --**********************************************************************************************************---
    address_generator_FSM: process (clk, rst)
    begin  -- process
        --------------------RESET----------------------------------------------------
        if rst = '1' then
            y <= IDLE;
        elsif clk'event and clk = '1' then  -- rising clock edge
            case y is
                --IDLE---------------------------------------------------------------
                when IDLE =>
                    if (start_fntt = '1') then
                        y <= FNTT;
                    elsif (start_pwm2 = '1') then
                        y <= PWM2;
                    elsif (start_intt = '1') then
                        y <= INTT;
                    else
                        y <= IDLE;
                    end if;
                --FNNT--------------------------------------------------------------
                when FNTT =>
                    if c_stage = "110" AND c_loop = "1111111" then --127
                        y <= IDLE;
                    else
                        y <= FNTT;
                    end if;
                --PWM2--------------------------------------------------------------
                when PWM2 =>
                    if c_pwm = "100" AND c_loop = "1111111" then --127
                        y <= IDLE;
                    else
                        y <= PWM2;
                    end if;
                --INTT--------------------------------------------------------------
                when INTT =>
                    if c_stage = "110" AND c_loop = "1111111" then --127
                        y <= IDLE;
                    else
                        y <= INTT;
                    end if;
            end case;
        end if;
    end process;

    --**********************************************************************************************************---
    -----------------------------------COUNTERS----------------------------------------------------------
    --**********************************************************************************************************---
    address_generator_counters : process (clk, rst)
        variable c_tw_plus1, c_tw_minus1, c_tw_1: std_logic_vector(8 downto 0);
    begin  --counters
        if rst='1' then
            c_stage <= (others=>'0');
            c_loop  <= (others=>'0');
            c_pwm   <= (others=>'0');
            c_tw    <= (others=>'0');

            c_tw_plus1 := (others=>'0');
            c_tw_minus1 := (others=>'0');
            c_tw_1 := (others=>'0');

        elsif clk'event and clk = '1' then

            c_tw_plus1 := std_logic_vector(unsigned(c_tw) + to_unsigned(1,9));
            c_tw_minus1 := std_logic_vector(unsigned(c_tw) - to_unsigned(1,9));
            c_tw_1 := "000000010"; --1 << 1

            if (start_fntt or start_intt or start_pwm2)='1' then
                c_stage <= (others=>'0');
                c_loop  <= (others=>'0');
                c_pwm   <= (others=>'0');
                if start_intt = '1' then
                    c_tw <= "001111111"; --127
                elsif start_pwm2 = '1' then
                    c_tw <= "010000010"; --130
                else
                    c_tw<= "000000001";
                end if;
            elsif y=FNTT then
                --end of a loop
                if c_loop = "1111111" then --127
                    if c_stage = "110" then --6
                        c_stage <= "110";
                    else
                        c_stage <= std_logic_vector(unsigned(c_stage) + to_unsigned(1,3));
                    end if;

                    c_loop <= "0000000";
                    c_tw <= std_logic_vector(unsigned(c_tw) + to_unsigned(1,9));
                --during the loop
                else
                    c_loop <= std_logic_vector(unsigned(c_loop) + to_unsigned(1,7));
                    c_stage <= c_stage;

                    case(c_stage) is
                        when "000" =>
                            c_tw <= c_tw;
                        when "001" =>
                            if c_loop(5 downto 0) = "111111" then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when "010" =>
                            if c_loop(4 downto 0) = "11111" then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when "011" =>
                            if c_loop(3 downto 0) = "1111" then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when "100" =>
                            if c_loop(2 downto 0) = "111" then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when "101" =>
                            if c_loop(1 downto 0) = "11" then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when "110" =>
                            if c_loop(0) = '1' then
                                c_tw <= c_tw_plus1;
                            else
                                c_tw <= c_tw;
                            end if;
                        when others=>
                            c_tw <= c_tw;
                    end case;
                end if;

            elsif y=PWM2 then

                c_stage <= (others=>'0');
                if c_pwm = "100" then
                    c_loop <= std_logic_vector(unsigned(c_loop) + to_unsigned(1,7));
                    c_pwm <= (others=>'0');
                    c_tw <= std_logic_vector(unsigned(c_tw) + to_unsigned(1,9));
--                    if c_loop(0)='1' then
--                        c_tw <= std_logic_vector(unsigned(c_tw) + to_unsigned(1,9));
--                    else 
--                        c_tw <= c_tw;
--                    end if;
                else
                    c_loop <= c_loop;
                    c_pwm <= std_logic_vector(unsigned(c_pwm) + to_unsigned(1,3));
                    c_tw <= c_tw;
                end if;
    


            elsif y=INTT then
                --end of a loop
                if c_loop = "1111111" then --127
                    if c_stage = "110" then --6
                        c_stage <= "110";
                    else
                        c_stage <= std_logic_vector(unsigned(c_stage) + to_unsigned(1,3));
                    end if;

                    c_loop <= "0000000";
                    c_tw <= std_logic_vector(unsigned(c_tw) - to_unsigned(1,9));
                --in the loop
                else
                    c_stage <= c_stage;
                    c_loop <= std_logic_vector(unsigned(c_loop) + to_unsigned(1,7));

                    case(c_stage) is
                        when "000" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(1 downto 0)="11" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "001" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(2 downto 0)="111" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "010" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(3 downto 0)="1111" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "011" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(4 downto 0)="11111" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "100" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(5 downto 0)="111111" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "101" =>
                            if c_loop(0) = '0' then
                                c_tw <= c_tw_minus1;
                            else
                                c_tw <= c_tw_plus1;
                                if c_loop(6 downto 0)="1111111" then
                                    c_tw <= std_logic_vector(unsigned(c_tw_plus1) - unsigned(c_tw_1));
                                else
                                    c_tw <=  c_tw_plus1;
                                end if;
                            end if;
                        when "110" => c_tw <= c_tw;
                        when others=>
                            c_tw <= c_tw;
                    end case;
                end if;

            else --curr_state == IDLE
                c_stage <= (others=>'0');
                c_loop  <= (others=>'0');
                c_pwm   <= (others=>'0');
                c_tw    <= (others=>'0');

            end if;

        end if;
        

    end process;
    
    


    --**********************************************************************************************************---
    -----------------------------------R_ADDR-------------------------------------------------------------------
    --**********************************************************************************************************---
    address_process_1 : process (clk, rst)
    begin
        if (rst = '1') then
            raddr(7) <= '0'; -- alternating addressing between stages
        elsif clk'event and clk = '1' then
            if (start_fntt = '1' or start_pwm2 = '1' or start_intt = '1') then
                if start_fntt='1' then
                    raddr(7) <= '0';
                else
                    raddr(7) <= '1';
                end if;

            elsif (raddr(6 downto 0) = "1111111" and (y = FNTT or y = INTT)) then
                -- negate for next stage
                raddr(7) <= not raddr(7);
            else
                -- otherwise, keep it
                raddr(7) <= raddr(7);
            end if;
        end if;
    end process;


    adress_process_2: process(clk, rst)
        variable temp2_a, temp2_b, temp2_c, temp2_d: std_logic_vector(2 downto 0);
        variable temp2_FNTT1, temp2_FNTT2, temp2_FNTT3, temp2_FNTT4, temp2_FNTT5, temp2_FNTT_sum: std_logic_vector(6 downto 0);
        variable temp2_PWM: std_logic_vector(0 downto 0);
        variable temp2_INTT1, temp2_INTT2, temp2_INTT3, temp2_INTT4, temp2_INTT5, temp2_INTT_sum: std_logic_vector(6 downto 0);
        variable temp2_cloop, temp2_cloop2: std_logic_vector(6 downto 0);

    begin
        if rst = '1' then
            raddr(6 downto 0) <= (others => '0');
            temp2_a := (others => '0');
            temp2_b := (others => '0');
            temp2_FNTT1 := (others => '0');
            temp2_FNTT2 := (others => '0');
            temp2_FNTT3 := (others => '0');
            temp2_FNTT4 := (others => '0');
            temp2_FNTT5 := (others => '0');
            temp2_cloop := (others => '0');
            temp2_FNTT_sum := (others => '0');

        elsif clk'event and clk = '1' then
            --iterators
            temp2_a := std_logic_vector(to_unsigned(6,3) - unsigned(c_stage)); --(6-c_stage)
            temp2_b := std_logic_vector(to_unsigned(7,3) - unsigned(c_stage)); --(7-c_stage)
            temp2_c := std_logic_vector(to_unsigned(1,3) + unsigned(c_stage)); --(c_stage+1)
            temp2_d := std_logic_vector(to_unsigned(2,3) + unsigned(c_stage)); --(c_stage+2)
            --intermediate variables    
            temp2_FNTT1 := "0000001";
            temp2_INTT1 := "0000001";
            temp2_FNTT2 := "000000" & c_loop(0);
            temp2_INTT2 := "000000" & c_loop(0);
            temp2_cloop := '0' & c_loop(6 downto 1);
            temp2_FNTT4 := c_loop;
            temp2_INTT4 := c_loop;

            if start_fntt = '1' or start_pwm2 = '1' or start_intt = '1' then
                raddr(6 downto 0) <= (others => '0');
            elsif y = FNTT then
                if c_stage = "110" then
                    raddr(6 downto 0) <= c_loop;
                else
                    for i in 1 to to_integer(unsigned(temp2_a)) loop
                        temp2_FNTT1 := temp2_FNTT1(5 downto 0) & '0';--(1<<(6-c_stage))
                        temp2_FNTT2 := temp2_FNTT2(5 downto 0) & '0'; --(c_loop[0] << (3'd6-c_stage)
                    end loop;

                    temp2_FNTT3 := std_logic_vector(unsigned(temp2_FNTT1)-to_unsigned(1,7));  --(1<<(6-c_stage)-1)

                    for i in 1 to to_integer(unsigned(temp2_b)) loop
                        temp2_FNTT4 := '0' & temp2_FNTT4(6 downto 1);--((c_loop>>(3'd7-c_stage))
                    end loop;

                    temp2_FNTT5 := temp2_FNTT4;

                    for i in 1 to to_integer(unsigned(temp2_b)) loop
                        temp2_FNTT5 := temp2_FNTT5(5 downto 0) & '0' ; --((c_loop>>(3'd7-c_stage)) << (3'd7-c_stage))
                    end loop;

                    temp2_FNTT_sum := (std_logic_vector(unsigned(temp2_FNTT2) + unsigned(temp2_FNTT5)));
                    raddr(6 downto 0) <= std_logic_vector(unsigned(temp2_cloop AND temp2_FNTT3)+ unsigned(temp2_FNTT_sum));
                end if;

            elsif y = PWM2 then
                if unsigned(c_pwm) < to_unsigned(2,3) then
                    temp2_PWM := "1";
                else
                    temp2_PWM := "0";
                end if;
                temp2_cloop2 := temp2_cloop(5 downto 0) & '0';
                raddr(6 downto 0) <= std_logic_vector(unsigned(temp2_PWM(0 downto 0))+ unsigned(temp2_cloop2));

            elsif y = INTT then
                if c_stage = "110" then
                    raddr(6 downto 0) <= c_loop;
                else
                    for i in 1 to to_integer(unsigned(temp2_c)) loop
                        temp2_INTT1 := temp2_INTT1(5 downto 0) & '0';--(1<<(1+c_stage))
                        temp2_INTT2 := temp2_INTT2(5 downto 0) & '0'; --(c_loop[0] << (1+c_stage)
                    end loop;

                    temp2_INTT3 := std_logic_vector(unsigned(temp2_INTT1)-to_unsigned(1,7));  --(1<<(1+c_stage)-1)

                    for i in 1 to to_integer(unsigned(temp2_d)) loop
                        temp2_INTT4 := '0' & temp2_INTT4(6 downto 1);--((c_loop>>(2+c_stage))
                    end loop;

                    temp2_INTT5 := temp2_INTT4;

                    for i in 1 to to_integer(unsigned(temp2_d)) loop
                        temp2_INTT5 := temp2_INTT5(5 downto 0) & '0' ; --((c_loop>>(2+c_stage)) << (2+c_stage))
                    end loop;

                    temp2_INTT_sum := (std_logic_vector(unsigned(temp2_INTT2) + unsigned(temp2_INTT5)));
                    raddr(6 downto 0) <= std_logic_vector(unsigned(temp2_cloop AND temp2_INTT3)+ unsigned(temp2_INTT_sum));
                end if;
            else
                raddr(6 downto 0) <= (others => '0');
            end if;
        end if;
    end process;


    adress_process_3: process (clk, rst)
        variable temp3: std_logic_vector(6 downto 0);
    begin
        if (rst = '1') then
            raddr_b_w <= (others=>'0');
        elsif clk'event and clk = '1' then
            if (y = PWM2) then
                temp3 := c_loop(6 downto 1) & '0';
                raddr_b_w <= std_logic_vector(unsigned(c_pwm(0 downto 0)) + unsigned(temp3));
            else
                raddr_b_w <= (others=>'0');
            end if;
        end if;
    end process;


    --**********************************************************************************************************---
    -----------------------------------W_ADDR-------------------------------------------------------------------
    --**********************************************************************************************************---

    ----------------------------- waddr,wen,brsel (c_loop)
    address_process_4: process (clk, rst)
    begin
        if (rst = '1') then
            waddre(7) <= '0';
            waddro(7) <= '0';
        elsif clk'event and clk = '1' then
            if start_fntt = '1' or start_pwm2 = '1' or start_intt = '1' then
                if start_fntt = '1' or start_pwm2 = '1' then
                    waddre(7) <= '1';
                    waddro(7) <= '1';
                else
                    waddre(7) <= '0';
                    waddro(7) <= '0';
                end if;
            elsif waddro(6 downto 0)= "1111111" and c_loop = "0000000" and (y= FNTT or y= INTT)then
                waddre(7) <= not waddre(7);
                waddro(7) <= not waddro(7);
            else
                waddre(7) <= waddre(7);
                waddro(7) <= waddro(7);
            end if;
        end if;
    end process;

    address_process5: process(clk, rst)
        variable temp5_a, temp5_b, temp5_c, temp5_d: std_logic_vector(2 downto 0);
        variable temp5_NTT_1, temp5_NTT_2, temp5_NTT_3, temp5_cloop: std_logic_vector(6 downto 0);
        variable temp5_INTT_1, temp5_INTT_2, temp5_INTT_3: std_logic_vector(6 downto 0);
        variable temp5_PWM2_1: std_logic_vector(0 downto 0);
        variable temp5_PWM2_2: std_logic_vector(6 downto 0);
    begin
        if rst = '1' then
            --iterators
            temp5_a := (others => '0');
            temp5_b := (others => '0');
            temp5_c := (others => '0');
            temp5_d := (others => '0');
            temp5_NTT_2 := (others => '0');
            temp5_NTT_1 := (others => '0');
            temp5_NTT_3 := (others => '0');
            temp5_INTT_2 := (others => '0');
            temp5_INTT_1 := (others => '0');
            temp5_INTT_3 := (others => '0');
            temp5_cloop := (others => '0');
            temp5_PWM2_1 := (others => '0');
            temp5_PWM2_2 := (others => '0');

            waddre(6 downto 0) <= (others=>'0');
            waddro(6 downto 0) <= (others=>'0');
            wen <= "0";
            brsel <= "0";
            brselen <= "0";

        elsif clk'event and clk = '1' then

            temp5_cloop := '0' & c_loop(6 downto 1);
            --iterators
            temp5_a := std_logic_vector(to_unsigned(6,3) - unsigned(c_stage)); --(6-c_stage)
            temp5_b := std_logic_vector(to_unsigned(7,3) - unsigned(c_stage)); --(7-c_stage)
            temp5_c := std_logic_vector(to_unsigned(1,3) + unsigned(c_stage)); --(c_stage+1)
            temp5_d := std_logic_vector(to_unsigned(2,3) + unsigned(c_stage)); --(c_stage+2)
            --intermediate variables 
            temp5_NTT_1 := "0000001";
            temp5_NTT_2 := c_loop;
            temp5_INTT_1 := "0000001";
            temp5_INTT_2 := c_loop;

            --at the beginning
            if start_fntt = '1' or start_pwm2 = '1' or start_intt = '1' then
                waddre(6 downto 0) <= (others=>'0');
                waddro(6 downto 0) <= (others=>'0');
                wen <= "0";
                brsel <= "0";
                brselen <= "0";
            --when FNTT
            elsif y=FNTT then

                if c_stage = "110" then
                    waddre(6 downto 0) <= c_loop;
                    waddro(6 downto 0) <= c_loop;
                else

                    for i in 1 to to_integer(unsigned(temp5_b)) loop
                        temp5_NTT_2 := '0' & temp5_NTT_2(6 downto 1); --((c_loop>>(3'd7-c_stage))
                    end loop;

                    temp5_NTT_3 := temp5_NTT_2;

                    for i in 1 to to_integer(unsigned(temp5_a)) loop
                        temp5_NTT_3 := temp5_NTT_3(5 downto 0) & '0' ; --((c_loop>>(3'd7-c_stage)) << (3'd6-c_stage))
                        temp5_NTT_1 := temp5_NTT_1(5 downto 0) & '0';
                    end loop;

                    waddre(6 downto 0) <= std_logic_vector(unsigned(temp5_cloop) + unsigned(temp5_NTT_3));
                    waddro(6 downto 0) <= std_logic_vector(unsigned(temp5_cloop) + unsigned(temp5_NTT_3) + unsigned(temp5_NTT_1));

                end if;

                wen         <= "1";
                brsel(0)    <= c_loop(0);
                brselen     <= "1";

            elsif y=PWM2 then
                if c_pwm > "000" and c_pwm < "011" then
                    temp5_PWM2_1 := "1"; 
                else
                    temp5_PWM2_1 := "0";
                end if;
               temp5_PWM2_2 := temp5_cloop(5 downto 0) & '0';
                waddre(6 downto 0) <= std_logic_vector(unsigned(temp5_PWM2_2) + unsigned(temp5_PWM2_1));
                waddro(6 downto 0) <= std_logic_vector(unsigned(temp5_PWM2_2) + unsigned(temp5_PWM2_1));
                
                if c_pwm = "011" then
                    wen <= "1";
                else
                    wen <= "0";
                end if;
                brsel       <= "0";
                brselen     <= "0";

            elsif y=INTT then

                if c_stage = "110" then
                    waddre(6 downto 0) <= c_loop;
                    waddro(6 downto 0) <= c_loop;
                else
                    for i in 1 to to_integer(unsigned(temp5_d)) loop
                        temp5_INTT_2 := '0' & temp5_INTT_2(6 downto 1); --((c_loop>>(2+c_stage))
                    end loop;
    
                    temp5_INTT_3 := temp5_INTT_2;
    
                    for i in 1 to to_integer(unsigned(temp5_c)) loop
                        temp5_INTT_3 := temp5_INTT_3(5 downto 0) & '0' ; --((c_loop>>(2+c_stage)) << (1+c_stage))
                        temp5_INTT_1 := temp5_INTT_1(5 downto 0) & '0'; --( 1 << (1+c_stage))
                    end loop;
    
                    waddre(6 downto 0) <= std_logic_vector(unsigned(temp5_cloop) + unsigned(temp5_INTT_3));
                    waddro(6 downto 0) <= std_logic_vector(unsigned(temp5_cloop) + unsigned(temp5_INTT_3) + unsigned(temp5_INTT_1));
    
                    wen <= "1";
                    brsel(0) <= c_loop(0);
                    brselen <= "1";
                end if;

            else
                waddre(6 downto 0) <= (others=>'0');
                waddro(6 downto 0) <= (others=>'0');
                wen         <= "0";
                brsel       <= "0";
                brselen     <= "0";
            end if;
        end if;
    end process;


    -----CT, PWM
    addressgenerator_process_3: process (clk)
    begin
        if clk'event and clk = '1' then
            if (rst = '1') then
                b_ct <= "0";
                b_pwm <= "0";
            else
                if y = FNTT or y=PWM2 then
                    b_ct <= "1";
                elsif y=INTT then
                    b_ct <= "0";
                else
                    b_ct <= b_ct;
                end if;
    
                if y=PWM2 then
                    if c_pwm = "100" then
                        b_pwm <= "1";
                    else
                        b_pwm <= "0";
                    end if;
                else
                    b_pwm <= "0";
                end if;
            end if;
        end if;
    end process;


    sre00: shiftreg
        generic map(
            SHIFT => 1,
            N     => 1
        )
        port map(
            shiftreg_in  => b_ct,
            rst          => rst,
            clk          => clk,
            shiftreg_out => ctd0
        );

    sre01: shiftreg
        generic map(
            SHIFT => 1,
            N     => 1
        )
        port map(
            shiftreg_in  => b_pwm,
            rst          => rst,
            clk          => clk,
            shiftreg_out => pwmd0
        );

    sre02: shiftreg
        generic map(
            SHIFT => 5,
            N     => 8
        )
        port map(
            shiftreg_in  => waddre,
            rst          => rst,
            clk          => clk,
            shiftreg_out => waddrd0
        );

    sre03: shiftreg
        generic map(
            SHIFT => 6,
            N     => 8
        )
        port map(
            shiftreg_in  => waddro,
            rst          => rst,
            clk          => clk,
            shiftreg_out => waddrd1
        );

    sre04: shiftreg
        generic map(
            SHIFT => 5,
            N     => 1
        )
        port map(
            shiftreg_in  => wen,
            rst          => rst,
            clk          => clk,
            shiftreg_out => wend0
        );

    sre05: shiftreg
        generic map(
            SHIFT => 6,
            N     => 1
        )
        port map(
            shiftreg_in  => wen,
            rst          => rst,
            clk          => clk,
            shiftreg_out => wend1
        );

    sre006: shiftreg
        generic map(
            SHIFT => 5,
            N     => 1
        )
        port map(
            shiftreg_in  => brsel,
            rst          => rst,
            clk          => clk,
            shiftreg_out => brseld0
        );

    sre07: shiftreg
        generic map(
            SHIFT => 6,
            N     => 1
        )
        port map(
            shiftreg_in  => brsel,
            rst          => rst,
            clk          => clk,
            shiftreg_out => brseld1
        );

    sre008: shiftreg
        generic map(
            SHIFT => 5,
            N     => 1
        )
        port map(
            shiftreg_in  => brselen,
            rst          => rst,
            clk          => clk,
            shiftreg_out => brselend0
        );

    sre009: shiftreg
        generic map(
            SHIFT => 6,
            N     => 1
        )
        port map(
            shiftreg_in  => brselen,
            rst          => rst,
            clk          => clk,
            shiftreg_out => brselend1
        );

    sre10: shiftreg
        generic map(
            SHIFT => 6,
            N     => 3
        )
        port map(
            shiftreg_in  => c_stage,
            rst          => rst,
            clk          => clk,
            shiftreg_out => stage_countd0
        );

    sre11: shiftreg
        generic map(
            SHIFT => 2,
            N     => 3
        )
        port map(
            shiftreg_in  => c_pwm,
            rst          => rst,
            clk          => clk,
            shiftreg_out => stage_count_pwmd0
        );
    sre12: shiftreg
        generic map(
            SHIFT => 2,
            N     => 7
        )
        port map(
            shiftreg_in  => c_loop,
            rst          => rst,
            clk          => clk,
            shiftreg_out => c_loop_pwmd0
        );

    sre13: shiftreg
        generic map(
            SHIFT => 1,
            N     => 7
        )
        port map(
            shiftreg_in  => raddr_b_w,
            rst          => rst,
            clk          => clk,
            shiftreg_out => raddr_b_wd0
        );

    sre14: shiftreg
        generic map(
            SHIFT => 1,
            N     => 9
        )
        port map(
            shiftreg_in  => c_tw,
            rst          => rst,
            clk          => clk,
            shiftreg_out => raddr_twd0
        );
        



    address_process_out: process(clk,rst)
    begin
        if (rst = '1') then
            --raddr(tw)
            CT <= '0';
            PWM <= '0';
            raddr0 <= (others=>'0');
            raddr1 <= (others=>'0');
            waddr0 <= (others=>'0');
            waddr1 <= (others=>'0');
            wen0 <= '0';
            wen1 <= '0';
            brsel0 <= '0';
            brsel1 <= '0';
            brselen0 <= '0';
            brselen1 <= '0';
            stage_count <= (others=>'0');
            stage_count_pwm <= (others=>'0');
            c_loop_pwm <= (others=>'0');

        elsif clk'event and clk = '1' then
            CT              <= ctd0(0);
            PWM             <= pwmd0(0);
            raddr0          <= raddr;
            raddr1          <= raddr;
            waddr0          <= waddrd0;
            waddr1          <= waddrd1;
            wen0            <= wend0(0);
            wen1            <= wend1(0);
            brsel0          <= brseld0(0);
            brsel1          <= brseld1(0);
            brselen0        <= brselend0(0);
            brselen1        <= brselend1(0);
            stage_count     <= stage_countd0;
            stage_count_pwm <= stage_count_pwmd0;
            c_loop_pwm      <= c_loop_pwmd0;
        end if;
    end process;

    raddr_b <= raddr_b_wd0;
    raddr_tw <= raddr_twd0;

end architecture behaviour;
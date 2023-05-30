library STD;
use STD.textio.all;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;


library work;


package param is


    constant q : integer := 3329;
    constant q_inv: integer := -3327;
    constant div2: integer := 1665;
    constant FNTT_CC: integer := 904;
    constant PWM2_CC: integer := 647;
    constant INTT_CC: integer := 904;
    constant MONT: integer := 1441;
    
    constant PE_NUMBER : integer := 1;
    constant barrett_v : integer := 20159; --((1 << 26) + q/2) / q
    
    
end package;
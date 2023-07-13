library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

  
entity keccak_tb is
end keccak_tb;

architecture structure of keccak_tb is

-- CONSTANTS --
constant D_WIDTH : integer := 1600;
constant D_KECCAK_WIDTH : integer := 64;
constant clk_period : time := 20 ns; 

-- SIGNALS --
signal clk, start    : std_logic := '0';
signal rst_n, status : std_logic;
signal din           : std_logic_vector (D_WIDTH-1 downto 0) := (others => '0');
signal dout          : std_logic_vector (D_WIDTH-1 downto 0);

file file_VECTORS : text;
file file_RESULTS : text open write_mode is "../output_results.txt";

-- COMPONENTS --

component keccak is
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    start   : in std_logic;
    din     : in  std_logic_vector(D_WIDTH-1 downto 0);
    dout    : out std_logic_vector(D_WIDTH-1 downto 0);
    status  : out std_logic);
end component; 


begin      

  keccak_i : keccak port map (
    clk,
    rst_n,
    start,
    din,
    dout,
    status);

  -- PROCEDURE THAT READS INPUT VALUES FROM FILE (64 bits written in HEX) --
  read_input : process
    variable v_ILINE            : line;
    variable input_value        : std_logic_vector (63 downto 0);
    variable cnt                : natural := 1;

    begin

      file_open(file_VECTORS, "../input_vectors.txt", read_mode);

      while not endfile(file_VECTORS) loop
        readline(file_VECTORS, v_ILINE);
        hread(v_ILINE, input_value);
        din((D_KECCAK_WIDTH*cnt)-1 downto D_KECCAK_WIDTH*(cnt-1)) <= input_value;
        cnt := cnt+1;
      end loop;

      file_close(file_VECTORS);
      wait ;
      
  end process;
  
  -- CLOCK PROCESS
  clk_process: process
    begin
      clk <= '0';
      wait for clk_period/2;
      clk <= '1';
      wait for clk_period/2;
  end process; 

  -- STIMULUS PROCESS
  stim_process : process
    begin
      wait for 10 ns;
      rst_n <= '0';
      wait for 40 ns;
      rst_n <= '1';
      wait for 10 ns;
      start <= '1';
      wait for 100 ns;
      start <= '0';
      wait;     
    end process;

-- PROCEDURE THAT WRITES OUTPUT VALUES TO FILE (64 bits written in HEX) --
  write_results : process
    variable v_OLINE            : line;
    variable count              : natural := 1;
    variable v_TIME             : time := 0 ns;
    
    -- sarebbe figo farlo fare nel loop per il simualtion time 

    begin
      wait on status;
      report "Datapath ready to do a new permutation";
      while ( status = '0') loop
        if (rising_edge(clk)) then 
          hwrite(v_OLINE, dout((D_KECCAK_WIDTH*count)-1 downto D_KECCAK_WIDTH*(count-1)), right, D_KECCAK_WIDTH);
          writeline(file_RESULTS, v_OLINE);
          count := count+1;
          wait on clk; 
          if (count = 26) then
             report "closing file";
             --v_TIME := now - v_TIME;
             file_close(file_RESULTS);
             wait;
          end if;
          else
            --to make sure it does not stuck in an infinite loop
            wait on clk; 
        end if; 
      end loop;  
  end process;
  
    
end structure; 


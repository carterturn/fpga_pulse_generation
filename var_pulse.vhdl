library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity var_pulse is
  port(clk, sel : in std_logic; period : in std_logic_vector(3 downto 0);
       output : out std_logic; counter : out std_logic_vector(2 downto 0));
end var_pulse;

architecture var_pulse_basic of var_pulse is
  signal counter_d : std_logic_vector(2 downto 0);
  signal counter_q : std_logic_vector(2 downto 0) := "000";
  signal period_d : std_logic_vector(3 downto 0) := "0100";
  signal period_q : std_logic_vector(3 downto 0) := "0100";
  signal output_d, output_q : std_logic;
  signal pulse_ready : std_logic;
begin
  output <= output_q;
  counter <= counter_q;

  process (clk) is
  begin
    if rising_edge(clk) then
      counter_q <= counter_d;
      if pulse_ready = '1' then
	counter_d <= "000";
      else
	counter_d <= std_logic_vector(unsigned(counter_q) + 1);
      end if;
      output_d <= output_q xor pulse_ready;
      output_q <= output_d;
      period_q <= period_d;
    end if;
  end process;

  process (sel) is
  begin
    if rising_edge(sel) then
      period_d <= period;
    end if;
  end process;

  process (counter_q, period_q) is
  begin
    if unsigned(counter_q) >= unsigned(period_q) then
      pulse_ready <= '1';
    else
      pulse_ready <= '0';
    end if;
  end process;
end architecture var_pulse_basic;


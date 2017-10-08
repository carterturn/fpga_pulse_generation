library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity pulses is
  port(clk, rst_n, cclk : in std_logic;
       spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
       spi_channel : out std_logic_vector(3 downto 0);
       avr_tx, avr_rx_busy : in std_logic; avr_rx : out std_logic;
       led : out std_logic_vector(7 downto 0);
       cube_ground : out std_logic_vector(3 downto 0); blue, red, green : out std_logic_vector(15 downto 0));  
end pulses;

architecture arch_pulses of pulses is
  component avr_interface
    port(clk, rst, cclk : in std_logic;
	 spi_ss, spi_mosi, spi_sck : in std_logic; spi_miso : out std_logic;
	 spi_channel : out std_logic_vector(3 downto 0);
	 tx : out std_logic; rx : in std_logic;
	 channel : in std_logic_vector(3 downto 0); -- new_sample : out std_logic;
	 -- sample : out std_logic_vector (9 downto 0); sample_channel : out std_logic_vector (3 downto 0);
	 tx_data : in std_logic_vector(7 downto 0); new_tx_data, tx_block : in std_logic; tx_busy : out std_logic;
	 rx_data : out std_logic_vector(7 downto 0); new_rx_data : out std_logic);
  end component;
  component var_pulse
      port(clk, sel : in std_logic; period : in std_logic_vector(3 downto 0);
	   output : out std_logic; counter : out std_logic_vector(2 downto 0));
  end component;
  signal rst : std_logic;
  signal rx_data, tx_data : std_logic_vector(7 downto 0);
  signal tx_busy, new_rx_data, new_tx_data : std_logic;

  signal counter_q, counter_d : std_logic_vector(27 downto 0);
  signal rx_idx : std_logic_vector(3 downto 0);
  signal pulse_period : std_logic_vector(3 downto 0);
begin
  rst <= not rst_n;
  
  spi_miso <= 'Z';
  spi_channel <= "ZZZZ";
  avr_rx <= 'Z';
  cube_ground <= "0000";
  red <= "0000000000000000";
  green <= "0000000000000000";

  led(3 downto 0) <= rx_idx;
  led(7 downto 4) <= counter_q(27 downto 24);

  pulse_period <= rx_data(3 downto 0);

  process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
	counter_q <= "0000000000000000000000000000";
      else
	counter_q <= counter_d;
      end if;
      counter_d <= std_logic_vector(unsigned(counter_q) + 1);
    end if;
  end process;

  process (new_rx_data) is
  begin
    if rising_edge(new_rx_data) then
      if rst = '1' then
	rx_idx <= "0001";
      else
	rx_idx(1) <= rx_idx(0);
	rx_idx(2) <= rx_idx(1);
	rx_idx(3) <= rx_idx(2);
	rx_idx(0) <= rx_idx(3);
      end if;
    end if;
  end process;
  
  pulse0 : var_pulse port map(counter_q(22), rx_idx(0), pulse_period, blue(0), blue(3 downto 1));
  pulse1 : var_pulse port map(counter_q(22), rx_idx(1), pulse_period, blue(4), blue(7 downto 5));
  pulse2 : var_pulse port map(counter_q(22), rx_idx(2), pulse_period, blue(8), blue(11 downto 9));
  pulse3 : var_pulse port map(counter_q(22), rx_idx(3), pulse_period, blue(12), blue(15 downto 13));

  avr_interface0: avr_interface port map(clk, rst, cclk, spi_ss, spi_mosi, spi_sck, spi_miso, spi_channel,
					 avr_rx, avr_tx, "1111", tx_data, new_tx_data,
					 avr_rx_busy, tx_busy, rx_data, new_rx_data);
end architecture arch_pulses;

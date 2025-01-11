
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity ip_block_axi_TB is
  GENERIC (
    EDGE_CLK : TIME := 2 ns
  );
end entity ip_block_axi_TB;
architecture rtl of ip_block_axi_TB is
  SIGNAL rst   : STD_LOGIC := '0';
  SIGNAL refclk : STD_LOGIC := '0';
  SIGNAL test_completed : BOOLEAN := false;
    COMPONENT ip_block_axi_TOP IS
      PORT (
        refclk : IN  STD_LOGIC;--! reference clock expect 250Mhz
        rst    : IN  STD_LOGIC--! sync active high reset. sync -> refclk
      );
    END COMPONENT;
begin

  ip_block_axi_TOP_inst : ip_block_axi_TOP
  PORT MAP
  (
    refclk => refclk,
    rst    => rst
  );

  test_clk_generator : PROCESS
  BEGIN
    IF NOT test_completed THEN
      refclk <= NOT refclk;
      WAIT for EDGE_CLK;
    ELSE
      WAIT;
    END IF;
  END PROCESS test_clk_generator;

  test_bench_main : PROCESS
  BEGIN
    test_completed <= true AFTER 50 ns;
    WAIT;
  END PROCESS test_bench_main;
end architecture rtl;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY umdom_TB IS
END ENTITY umdom_TB;

ARCHITECTURE behavior OF umdom_TB IS

  COMPONENT umdom_TOP
    PORT (
      -- AXI Slave interface
      S_AXI_ACLK    : IN  STD_LOGIC;
      S_AXI_ARESETN : IN  STD_LOGIC;

      S_AXI_AWADDR  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_AWVALID : IN  STD_LOGIC;
      S_AXI_AWREADY : OUT STD_LOGIC;
      S_AXI_WDATA   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_WVALID  : IN  STD_LOGIC;
      S_AXI_WREADY  : OUT STD_LOGIC;
      S_AXI_BRESP   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_BVALID  : OUT STD_LOGIC;
      S_AXI_BREADY  : IN  STD_LOGIC;
      S_AXI_ARADDR  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_ARVALID : IN  STD_LOGIC;
      S_AXI_ARREADY : OUT STD_LOGIC;
      S_AXI_RDATA   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      S_AXI_RVALID  : OUT STD_LOGIC;
      S_AXI_RREADY  : IN  STD_LOGIC;

      -- Пользовательские сигналы
      temp_sensor_in : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
      temp_valid     : IN  STD_LOGIC;
      window_position: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
      window_control : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      window_busy    : IN  STD_LOGIC
    );
  END COMPONENT;

  -- Тестовые сигналы для AXI
  SIGNAL s_axi_aclk      : STD_LOGIC := '0';
  SIGNAL s_axi_aresetn   : STD_LOGIC := '0';  -- Будет активным 0
  SIGNAL s_axi_awaddr    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_awvalid   : STD_LOGIC := '0';
  SIGNAL s_axi_awready   : STD_LOGIC;
  SIGNAL s_axi_wdata     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_wvalid    : STD_LOGIC := '0';
  SIGNAL s_axi_wready    : STD_LOGIC;
  SIGNAL s_axi_bresp     : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL s_axi_bvalid    : STD_LOGIC;
  SIGNAL s_axi_bready    : STD_LOGIC := '1';
  SIGNAL s_axi_araddr    : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_arvalid   : STD_LOGIC := '0';
  SIGNAL s_axi_arready   : STD_LOGIC;
  SIGNAL s_axi_rdata     : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL s_axi_rvalid    : STD_LOGIC;
  SIGNAL s_axi_rready    : STD_LOGIC := '1';

  -- Датчики/окно
  SIGNAL temp_sensor_in  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
  SIGNAL temp_valid      : STD_LOGIC := '0';
  SIGNAL window_position : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL window_control  : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL window_busy     : STD_LOGIC := '0';

  -- Адреса регистров
  CONSTANT ADDR_TEMP_THRESHOLD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
  CONSTANT ADDR_WINDOW_CTRL    : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"04";
  CONSTANT ADDR_STATUS         : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"08";

BEGIN

  ------------------------------------------------------------------
  -- Экземпляр DUT
  ------------------------------------------------------------------
  DUT: umdom_TOP
    PORT MAP (
      -- AXI
      S_AXI_ACLK    => s_axi_aclk,
      S_AXI_ARESETN => s_axi_aresetn,

      S_AXI_AWADDR  => s_axi_awaddr,
      S_AXI_AWVALID => s_axi_awvalid,
      S_AXI_AWREADY => s_axi_awready,
      S_AXI_WDATA   => s_axi_wdata,
      S_AXI_WVALID  => s_axi_wvalid,
      S_AXI_WREADY  => s_axi_wready,
      S_AXI_BRESP   => s_axi_bresp,
      S_AXI_BVALID  => s_axi_bvalid,
      S_AXI_BREADY  => s_axi_bready,
      S_AXI_ARADDR  => s_axi_araddr,
      S_AXI_ARVALID => s_axi_arvalid,
      S_AXI_ARREADY => s_axi_arready,
      S_AXI_RDATA   => s_axi_rdata,
      S_AXI_RVALID  => s_axi_rvalid,
      S_AXI_RREADY  => s_axi_rready,

      -- Прочие
      temp_sensor_in => temp_sensor_in,
      temp_valid     => temp_valid,
      window_position=> window_position,
      window_control => window_control,
      window_busy    => window_busy
    );

  ------------------------------------------------------------------
  -- Генерация тактового сигнала
  ------------------------------------------------------------------
  clk_process: PROCESS
  BEGIN
    s_axi_aclk <= '0';
    WAIT FOR 5 ns;
    s_axi_aclk <= '1';
    WAIT FOR 5 ns;
  END PROCESS;

  ------------------------------------------------------------------
  -- Процесс сброса (активный 0)
  ------------------------------------------------------------------
  reset_process: PROCESS
  BEGIN
    -- В начале держим сброс в '0'
    s_axi_aresetn <= '0';
    WAIT FOR 100 ns;
    -- Снимаем сброс, делаем '1'
    s_axi_aresetn <= '1';
    WAIT;
  END PROCESS;

  ------------------------------------------------------------------
  -- Основной процесс тестирования
  ------------------------------------------------------------------
  stim_proc: PROCESS
  BEGIN
    -- Ждём чуть больше 100 ns, чтобы сброс успел сняться
    WAIT FOR 110 ns;

    -- Тест 1: Установка порога температуры
    s_axi_awaddr  <= x"000000" & ADDR_TEMP_THRESHOLD;
    s_axi_awvalid <= '1';
    s_axi_wdata   <= x"000001F4"; -- 50°C
    s_axi_wvalid  <= '1';
    WAIT UNTIL rising_edge(s_axi_aclk) AND s_axi_awready = '1' AND s_axi_wready = '1';
    s_axi_awvalid <= '0';
    s_axi_wvalid  <= '0';
    -- Ожидаем, когда BVALID
    WAIT UNTIL rising_edge(s_axi_aclk) AND s_axi_bvalid = '1';
    WAIT FOR 20 ns;

    -- Тест 2: Проверка открытия окна
    temp_valid     <= '1';
    temp_sensor_in <= x"200"; -- 51.2°C
    window_position<= x"00";  -- Окно закрыто
    WAIT FOR 100 ns;
    ASSERT (window_control = "01")
      REPORT "Test 2 Failed: Window should open at high temperature"
      SEVERITY ERROR;

    -- Тест 3: Проверка закрытия окна
    temp_sensor_in <= x"1E0"; -- 48.8°C
    window_position<= x"FF";  -- Окно открыто
    WAIT FOR 100 ns;
    ASSERT (window_control = "10")
      REPORT "Test 3 Failed: Window should close at low temperature"
      SEVERITY ERROR;

    -- Завершение симуляции
    WAIT FOR 100 ns;
    ASSERT FALSE
      REPORT "Simulation completed successfully"
      SEVERITY NOTE;
    WAIT;
  END PROCESS;

END ARCHITECTURE;

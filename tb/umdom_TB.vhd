LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY umdom_TB IS
END ENTITY umdom_TB;

ARCHITECTURE behavior OF umdom_TB IS

  COMPONENT umdom_TOP IS
    PORT (
      refclk          : IN  STD_LOGIC;
      sys_rst_n       : IN  STD_LOGIC;
      temp_sensor_in  : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
      temp_valid      : IN  STD_LOGIC;
      window_busy     : IN  STD_LOGIC;
      window_control  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      window_position : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_awaddr   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axi_awvalid  : OUT STD_LOGIC;
      m_axi_awready  : IN  STD_LOGIC;
      m_axi_wdata    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axi_wvalid   : OUT STD_LOGIC;
      m_axi_wready   : IN  STD_LOGIC;
      m_axi_bresp    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_bvalid   : IN  STD_LOGIC;
      m_axi_bready   : OUT STD_LOGIC;
      m_axi_araddr   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axi_arvalid  : OUT STD_LOGIC;
      m_axi_arready  : IN  STD_LOGIC;
      m_axi_rdata    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axi_rresp    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_rvalid   : IN  STD_LOGIC;
      m_axi_rready   : OUT STD_LOGIC
    );
  END COMPONENT;

  -- Тестовые сигналы
  SIGNAL refclk          : STD_LOGIC := '0';
  SIGNAL sys_rst_n       : STD_LOGIC := '0';
  SIGNAL temp_sensor_in  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
  SIGNAL temp_valid      : STD_LOGIC := '0';
  SIGNAL window_position : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL window_control  : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL window_busy     : STD_LOGIC := '0';

  -- Добавляем сигналы AXI
  SIGNAL m_axi_awaddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_awvalid : STD_LOGIC;
  SIGNAL m_axi_awready : STD_LOGIC := '1';  -- Инициализируем в '1'
  SIGNAL m_axi_wdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_wvalid  : STD_LOGIC;
  SIGNAL m_axi_wready  : STD_LOGIC := '1';  -- Инициализируем в '1'
  SIGNAL m_axi_bresp   : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  SIGNAL m_axi_bvalid  : STD_LOGIC := '0';  -- Инициализируем в '0'
  SIGNAL m_axi_bready  : STD_LOGIC;

  -- Добавляем сигналы AXI для чтения
  SIGNAL m_axi_araddr  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_arvalid : STD_LOGIC;
  SIGNAL m_axi_arready : STD_LOGIC := '1';  -- Инициализируем в '1'
  SIGNAL m_axi_rdata   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL m_axi_rresp   : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
  SIGNAL m_axi_rvalid  : STD_LOGIC := '0';  -- Инициализируем в '0'
  SIGNAL m_axi_rready  : STD_LOGIC;

  -- Добавляем память для эмуляции
  SIGNAL memory_data : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

  -- Константы для временных параметров
  CONSTANT CLK_PERIOD : TIME := 10 ns;

BEGIN

  -- Генерация тактового сигнала
  clock_process: PROCESS
  BEGIN
    refclk <= '0';
    WAIT FOR CLK_PERIOD/2;
    refclk <= '1';
    WAIT FOR CLK_PERIOD/2;
  END PROCESS;

  -- Процесс тестирования
  stim_proc: PROCESS
  BEGIN
    -- Инициализация
    sys_rst_n <= '0';
    temp_valid <= '0';
    temp_sensor_in <= (OTHERS => '0');
    window_position <= (OTHERS => '0');
    window_busy <= '0';
    
    -- Ждем 10 тактов для сброса
    WAIT FOR CLK_PERIOD * 10;
    
    -- Снимаем сброс
    WAIT UNTIL rising_edge(refclk);
    sys_rst_n <= '1';
    
    -- Ждем 2 такта после сброса
    WAIT FOR CLK_PERIOD * 2;
    
    -- Тест 1: Открытие окна при высокой температуре
    WAIT UNTIL rising_edge(refclk);
    temp_sensor_in <= x"200"; -- 51.2°C
    window_position <= x"00"; -- Окно закрыто
    temp_valid <= '1';
    
    -- Ждем 5 тактов
    WAIT FOR CLK_PERIOD * 5;
    
    -- Сбрасываем temp_valid
    WAIT UNTIL rising_edge(refclk);
    temp_valid <= '0';
    
    -- Ждем 2 такта между тестами
    WAIT FOR CLK_PERIOD * 2;
    
    -- Тест 2: Закрытие окна при низкой температуре
    WAIT UNTIL rising_edge(refclk);
    temp_sensor_in <= x"1E0"; -- 48.8°C
    window_position <= x"FF"; -- Окно открыто
    temp_valid <= '1';
    
    -- Ждем 5 тактов
    WAIT FOR CLK_PERIOD * 5;
    
    -- Сбрасываем temp_valid
    WAIT UNTIL rising_edge(refclk);
    temp_valid <= '0';
    
    -- Ждем 2 такта между тестами
    WAIT FOR CLK_PERIOD * 2;
    
    -- Тест 3: Проверка реакции на занятость окна
    WAIT UNTIL rising_edge(refclk);
    temp_sensor_in <= x"200"; -- Высокая температура
    window_position <= x"00"; -- Окно закрыто
    window_busy <= '1';
    temp_valid <= '1';
    
    -- Ждем 5 тактов
    WAIT FOR CLK_PERIOD * 5;
    
    -- Завершение симуляции
    WAIT FOR CLK_PERIOD * 5;
    ASSERT FALSE
      REPORT "Simulation completed successfully"
      SEVERITY NOTE;
    WAIT;
  END PROCESS;

  -- Обновляем процесс эмуляции памяти
  memory_sim: PROCESS(refclk)
    VARIABLE l: LINE;
  BEGIN
    IF rising_edge(refclk) THEN
      -- Обработка записи
      IF m_axi_awvalid = '1' AND m_axi_wvalid = '1' AND m_axi_awready = '1' AND m_axi_wready = '1' THEN
        memory_data <= m_axi_wdata;  -- Сохраняем данные в память
        m_axi_bvalid <= '1';
      ELSIF m_axi_bvalid = '1' AND m_axi_bready = '1' THEN
        m_axi_bvalid <= '0';
      END IF;

      -- Обработка чтения
      IF m_axi_arvalid = '1' AND m_axi_arready = '1' THEN
        m_axi_rdata <= memory_data;  -- Возвращаем последнее записанное значение
        m_axi_rvalid <= '1';
      ELSIF m_axi_rvalid = '1' AND m_axi_rready = '1' THEN
        m_axi_rvalid <= '0';
      END IF;
    END IF;
  END PROCESS;

  -- Упрощаем процесс управления ready сигналами
  ready_control: PROCESS(refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF sys_rst_n = '0' THEN
        m_axi_awready <= '1';
        m_axi_wready <= '1';
        m_axi_arready <= '1';
      ELSE
        -- Управление ready для записи
        m_axi_awready <= NOT m_axi_bvalid;
        m_axi_wready <= NOT m_axi_bvalid;
        
        -- Управление ready для чтения
        m_axi_arready <= NOT m_axi_rvalid;
      END IF;
    END IF;
  END PROCESS;

  -- Обновляем экземпляр тестируемого модуля
  DUT : umdom_TOP
  PORT MAP (
    refclk          => refclk,
    sys_rst_n       => sys_rst_n,
    temp_sensor_in  => temp_sensor_in,
    temp_valid      => temp_valid,
    window_busy     => window_busy,
    window_control  => window_control,
    window_position => window_position,
    m_axi_awaddr   => m_axi_awaddr,
    m_axi_awvalid  => m_axi_awvalid,
    m_axi_awready  => m_axi_awready,
    m_axi_wdata    => m_axi_wdata,
    m_axi_wvalid   => m_axi_wvalid,
    m_axi_wready   => m_axi_wready,
    m_axi_bresp    => m_axi_bresp,
    m_axi_bvalid   => m_axi_bvalid,
    m_axi_bready   => m_axi_bready,
    m_axi_araddr   => m_axi_araddr,
    m_axi_arvalid  => m_axi_arvalid,
    m_axi_arready  => m_axi_arready,
    m_axi_rdata    => m_axi_rdata,
    m_axi_rresp    => m_axi_rresp,
    m_axi_rvalid   => m_axi_rvalid,
    m_axi_rready   => m_axi_rready
  );

END ARCHITECTURE;

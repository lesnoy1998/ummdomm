LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY umdom_TOP IS
  PORT (
    refclk          : IN  STD_LOGIC;
    sys_rst_n       : IN  STD_LOGIC;
    temp_sensor_in  : IN  STD_LOGIC_VECTOR (11 DOWNTO 0);
    temp_valid      : IN  STD_LOGIC;
    window_busy     : IN  STD_LOGIC;
    window_control  : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
    window_position : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
    
    -- Добавляем порты AXI
    m_axi_awaddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_awvalid : OUT STD_LOGIC;
    m_axi_awready : IN  STD_LOGIC;
    m_axi_wdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_wvalid  : OUT STD_LOGIC;
    m_axi_wready  : IN  STD_LOGIC;
    m_axi_bresp   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_bvalid  : IN  STD_LOGIC;
    m_axi_bready  : OUT STD_LOGIC;
    
    -- Добавляем порты AXI для чтения
    m_axi_araddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_arvalid : OUT STD_LOGIC;
    m_axi_arready : IN  STD_LOGIC;
    m_axi_rdata   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_rresp   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_rvalid  : IN  STD_LOGIC;
    m_axi_rready  : OUT STD_LOGIC
  );
END ENTITY umdom_TOP;

ARCHITECTURE rtl OF umdom_TOP IS
  -- Константы для управления окном
  CONSTANT TEMP_THRESHOLD : unsigned(11 DOWNTO 0) := x"1F0"; -- 49.6°C
  
  -- Сигналы управления
  SIGNAL window_control_reg : STD_LOGIC_VECTOR(1 DOWNTO 0);
  
  -- Добавляем сигналы для AXI
  SIGNAL axi_awvalid_reg : STD_LOGIC := '0';
  SIGNAL axi_wvalid_reg  : STD_LOGIC := '0';
  SIGNAL axi_bready_reg  : STD_LOGIC := '1';
  SIGNAL write_pending   : STD_LOGIC := '0';
  
  -- Добавляем сигналы для чтения
  SIGNAL axi_arvalid_reg : STD_LOGIC := '0';
  SIGNAL axi_rready_reg  : STD_LOGIC := '1';
  SIGNAL read_pending    : STD_LOGIC := '0';
  SIGNAL prev_temp       : STD_LOGIC_VECTOR(11 DOWNTO 0);
  
  -- Состояния для конечного автомата
  TYPE state_type IS (IDLE, WRITING, READING);
  SIGNAL current_state : state_type := IDLE;

BEGIN
  -- Процесс управления записью/чтением памяти
  memory_process : PROCESS(refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF sys_rst_n = '0' THEN
        axi_awvalid_reg <= '0';
        axi_wvalid_reg  <= '0';
        axi_arvalid_reg <= '0';
        write_pending   <= '0';
        read_pending    <= '0';
        current_state   <= IDLE;
      ELSE
        CASE current_state IS
          WHEN IDLE =>
            IF temp_valid = '1' THEN
              -- Начинаем запись
              axi_awvalid_reg <= '1';
              axi_wvalid_reg  <= '1';
              write_pending   <= '1';
              current_state   <= WRITING;
            END IF;

          WHEN WRITING =>
            IF m_axi_awready = '1' AND m_axi_wready = '1' AND write_pending = '1' THEN
              -- Завершаем запись и начинаем чтение
              axi_awvalid_reg <= '0';
              axi_wvalid_reg  <= '0';
              write_pending   <= '0';
              axi_arvalid_reg <= '1';
              read_pending    <= '1';
              current_state   <= READING;
            END IF;

          WHEN READING =>
            IF m_axi_arready = '1' THEN
              axi_arvalid_reg <= '0';
            END IF;
            
            IF m_axi_rvalid = '1' AND read_pending = '1' THEN
              prev_temp <= m_axi_rdata(11 DOWNTO 0);
              read_pending <= '0';
              current_state <= IDLE;
            END IF;
        END CASE;
      END IF;
    END IF;
  END PROCESS;

  -- Процесс управления окном
  window_control_process : PROCESS(refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF sys_rst_n = '0' THEN
        window_control_reg <= "00";
      ELSE
        IF temp_valid = '1' AND window_busy = '0' THEN
          -- Если температура выше порога и окно закрыто - открываем
          IF unsigned(temp_sensor_in) > TEMP_THRESHOLD AND window_position = x"00" THEN
            window_control_reg <= "01";  -- Команда открытия
          -- Если температура ниже порога и окно открыто - закрываем
          ELSIF unsigned(temp_sensor_in) < TEMP_THRESHOLD AND window_position = x"FF" THEN
            window_control_reg <= "10";  -- Команда закрытия
          ELSE
            window_control_reg <= "00";  -- Нет действия
          END IF;
        ELSE
          window_control_reg <= "00";  -- Нет действия при неактивном датчике или занятом окне
        END IF;
      END IF;
    END IF;
  END PROCESS;

  -- Назначение сигналов AXI
  m_axi_awaddr  <= x"00000000";  -- Адрес для записи
  m_axi_araddr  <= x"00000000";  -- Тот же адрес для чтения
  m_axi_awvalid <= axi_awvalid_reg;
  m_axi_arvalid <= axi_arvalid_reg;
  m_axi_wdata   <= x"00000" & temp_sensor_in;
  m_axi_wvalid  <= axi_wvalid_reg;
  m_axi_bready  <= axi_bready_reg;
  m_axi_rready  <= axi_rready_reg;
  
  -- Назначение выходного сигнала
  window_control <= window_control_reg;

END ARCHITECTURE rtl;

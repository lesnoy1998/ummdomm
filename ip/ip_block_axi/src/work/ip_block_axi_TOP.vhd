LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ip_block_axi_TOP IS
  GENERIC (
    DATA_WIDTH : INTEGER := 64;
    ADDR_WIDTH : INTEGER := 19
  );
  PORT (
    ----------------------------------------------------------------------------
    -- AXI4-Lite (или AXI4) Slave Interface
    ----------------------------------------------------------------------------
    --AXI4 MM interface
    m_axi_aclk    : IN STD_LOGIC := '1';
    m_axi_aresetn : IN STD_LOGIC := '0';

    m_axi_arready : IN  STD_LOGIC := '1';
    m_axi_arvalid : OUT STD_LOGIC;
    m_axi_araddr  : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_arid    : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
    m_axi_arlen   : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    m_axi_arsize  : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
    m_axi_arburst : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

    m_axi_rvalid : IN  STD_LOGIC := '0';
    m_axi_rlast  : IN  STD_LOGIC := '0';
    m_axi_rready : OUT STD_LOGIC;
    m_axi_rdata  : IN  STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    m_axi_rid    : IN  STD_LOGIC_VECTOR (3 DOWNTO 0)             := (OTHERS => '0');
    m_axi_rresp  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0)              := "00";

    m_axi_awready : IN  STD_LOGIC := '0';
    m_axi_awvalid : OUT STD_LOGIC;
    m_axi_awaddr  : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_awid    : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
    m_axi_awlen   : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    m_axi_awsize  : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
    m_axi_awburst : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

    m_axi_wready : IN  STD_LOGIC := '0';
    m_axi_wvalid : OUT STD_LOGIC;
    m_axi_wid    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_wdata  : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    m_axi_wlast  : OUT STD_LOGIC;

    m_axi_bready : OUT STD_LOGIC;
    m_axi_bvalid : IN  STD_LOGIC := '0';
    m_axi_bresp  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_bid    : IN  STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------------------------------------------
    -- Прочие пользовательские порты (температура, окно и т.д.)
    ----------------------------------------------------------------------------
    temp_sensor_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0); -- АЦП температуры (12 бит)
    temp_valid     : IN STD_LOGIC;                     -- Валидность данных температуры

    window_position : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); -- Текущее положение окна
    window_control  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- Управление приводом (00-стоп, 01-открыть, 10-закрыть)
    window_busy     : IN  STD_LOGIC                     -- Флаг занятости привода
  );
END ENTITY ip_block_axi_TOP;

ARCHITECTURE rtl OF ip_block_axi_TOP IS

  ----------------------------------------------------------------------------
  -- Внутренние сигналы
  ----------------------------------------------------------------------------
  SIGNAL awready_internal : STD_LOGIC                    := '0';
  SIGNAL wready_internal  : STD_LOGIC                    := '0';
  SIGNAL bvalid_internal  : STD_LOGIC                    := '0';
  SIGNAL bresp_internal   : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";

  -- Регистры для хранения настроек
  SIGNAL temp_threshold     : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"1F4"; -- 50°C по умолчанию
  SIGNAL window_auto_mode   : STD_LOGIC                     := '1';    -- Автоматический режим
  SIGNAL window_control_reg : STD_LOGIC_VECTOR(1 DOWNTO 0)  := "00";

BEGIN

  -- ----------------------------------------------------------------------------
  -- -- Процесс записи (AXI Write)
  -- ----------------------------------------------------------------------------
  -- axi_write_process : PROCESS (S_AXI_ACLK)
  -- BEGIN
  --   IF rising_edge(S_AXI_ACLK) THEN
  --     -- Переходим на сброс, активный НИЗКИЙ
  --     IF (S_AXI_ARESETN = '0') THEN
  --       awready_internal <= '0';
  --       wready_internal  <= '0';
  --       bvalid_internal  <= '0';
  --       bresp_internal   <= "00";
  --       temp_threshold   <= x"1F4";
  --       window_auto_mode <= '1';

  --     ELSE
  --       -- По умолчанию готовы принимать новые транзакции
  --       awready_internal <= '1';
  --       wready_internal  <= '1';

  --       IF (S_AXI_AWVALID = '1' AND S_AXI_WVALID = '1') THEN
  --         -- Пришли адрес и данные одновременно
  --         bvalid_internal <= '1';
  --         bresp_internal  <= "00"; -- OKAY response

  --         -- Пример записи в регистры:
  --         CASE S_AXI_AWADDR(7 DOWNTO 0) IS
  --           WHEN x"00" =>
  --             temp_threshold <= S_AXI_WDATA(11 DOWNTO 0);
  --           WHEN x"04" =>
  --             window_auto_mode <= S_AXI_WDATA(0);
  --           WHEN OTHERS =>
  --             NULL;
  --         END CASE;

  --       ELSIF (S_AXI_BREADY = '1' AND bvalid_internal = '1') THEN
  --         -- Сбрасываем BVALID после того, как мастер прочитал
  --         bvalid_internal <= '0';
  --       END IF;

  --     END IF;
  --   END IF;
  -- END PROCESS;

  -- ----------------------------------------------------------------------------
  -- -- Процесс управления окном (пример логики)
  -- ----------------------------------------------------------------------------
  -- window_control_process : PROCESS (S_AXI_ACLK)
  -- BEGIN
  --   IF rising_edge(S_AXI_ACLK) THEN
  --     IF (S_AXI_ARESETN = '0') THEN
  --       window_control_reg <= "00";
  --     ELSE
  --       IF window_auto_mode = '1' AND temp_valid = '1' THEN
  --         IF unsigned(temp_sensor_in) > unsigned(temp_threshold) AND (window_position = x"00") THEN
  --           window_control_reg <= "01";
  --         ELSIF unsigned(temp_sensor_in) < unsigned(temp_threshold) AND (window_position = x"FF") THEN
  --           window_control_reg <= "10";
  --         ELSE
  --           window_control_reg <= "00";
  --         END IF;
  --       END IF;
  --     END IF;
  --   END IF;
  -- END PROCESS;

  -- ----------------------------------------------------------------------------
  -- -- Выходные сигналы AXI
  -- ----------------------------------------------------------------------------
  -- S_AXI_AWREADY <= awready_internal;
  -- S_AXI_WREADY  <= wready_internal;
  -- S_AXI_BVALID  <= bvalid_internal;
  -- S_AXI_BRESP   <= bresp_internal;

  -- ----------------------------------------------------------------------------
  -- -- Пример заглушки для чтения (AR не обрабатываем)
  -- ----------------------------------------------------------------------------
  -- S_AXI_ARREADY <= '0';
  -- S_AXI_RVALID  <= '0';
  -- S_AXI_RDATA   <= (OTHERS => '0');

  -- ----------------------------------------------------------------------------
  -- -- Выходы управления окном
  -- ----------------------------------------------------------------------------
  -- window_control <= window_control_reg;

END ARCHITECTURE rtl;

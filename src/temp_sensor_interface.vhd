ENTITY temp_sensor_interface IS
  PORT (
    clk           : IN  STD_LOGIC;
    reset         : IN  STD_LOGIC;
    -- Интерфейс I2C/SPI для реального датчика
    scl           : OUT STD_LOGIC;
    sda           : INOUT STD_LOGIC;
    -- Выходные данные
    temp_data     : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    temp_valid    : OUT STD_LOGIC
  );
END ENTITY; 
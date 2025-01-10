ENTITY window_controller IS
  PORT (
    clk            : IN  STD_LOGIC;
    reset          : IN  STD_LOGIC;
    -- Управление
    control        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    -- Выходы на драйвер двигателя
    motor_phase_a  : OUT STD_LOGIC;
    motor_phase_b  : OUT STD_LOGIC;
    -- Обратная связь
    position       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    busy          : OUT STD_LOGIC
  );
END ENTITY; 
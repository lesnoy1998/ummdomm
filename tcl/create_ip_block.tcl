# Устанавливаем порядок компиляции
update_compile_order -fileset sources_1

# Создаем блочный дизайн
create_bd_design "design_1"

create_bd_cell -type ip -vlnv xilinx.com:user:umdom_TOP:1.0 umdom_TOP_0

# Создаем порты блочного дизайна
create_bd_port -dir I -type clk clk
create_bd_port -dir I -type rst reset

# Подключаем порты к модулю umdom_TOP
connect_bd_net [get_bd_ports clk] [get_bd_pins umdom_TOP_0/S_AXI_ACLK]
connect_bd_net [get_bd_ports reset] [get_bd_pins umdom_TOP_0/S_AXI_ARESETN]

# Генерируем обертку
make_wrapper -files [get_files $CURRENT_DIR/design_1/design_1.bd] -top

# Добавляем обертку в проект
add_files -norecurse $CURRENT_DIR/design_1/hdl/design_1_wrapper.vhd

# Обновляем порядок компиляции
update_compile_order -fileset sources_1

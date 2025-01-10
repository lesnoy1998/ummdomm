# create_block_design.tcl

# 1) Создаём/открываем новый блочный дизайн
create_bd_design "design_1"
open_bd_design "design_1"

# 2) Создаём Clock Wizard (генерация такта)
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 sys_clk_0
set_property -dict [list \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLK_OUT1_PORT {clk_out1} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
] [get_bd_cells sys_clk_0]

# 3) Создаём Proc Sys Reset (синхронный сброс)
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 sys_reset_0

# 4) Создаём AXI Interconnect (маршрутизация AXI)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0

# 5) Создаём экземпляр вашего IP (umdom_TOP) - 
#    Учитывая, что в component.xml у вас:
#      <vendor>   xilinx.com       </vendor>
#      <library>  user             </library>
#      <name>     umdom_TOP        </name>
#      <version>  1.0              </version>
create_bd_cell -type ip -vlnv xilinx.com:user:umdom_TOP:1.0 umdom_TOP_0

# 6) Создаём AXI BRAM Controller + Block Memory 
#    (если хотите сделать, как в примере преподавателя)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0

# 7) Создаём внешний AXI Master-порт (S00_AXI) 
#    - чтобы кто-то "сверху" мог стучаться в umdom_TOP и в BRAM
# Создаём интерфейсный порт "S00_AXI" (без принудительного -mode):
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports S00_AXI]

# 8) Создаём внешние single-ended порты 
#    для пользовательских сигналов (температура и т.д.)
create_bd_port -dir I -from 11 -to 0 temp_sensor_in
create_bd_port -dir I temp_valid
create_bd_port -dir I -from 7 -to 0 window_position
create_bd_port -dir I window_busy
create_bd_port -dir O -from 1 -to 0 window_control

# 9) Создаём внешние порты для такта и сброса (часто сброс активен высокий)
create_bd_port -dir I -type clk -freq_hz 100000000 clock_rtl
create_bd_port -dir I -type rst reset_rtl

#
# ===== Соединяем Clock Wizard / Proc Sys Reset / Interconnect / IP =====
#

# 10) Подаём внешний clock на вход clk_wiz
connect_bd_net [get_bd_pins sys_clk_0/clk_in1] [get_bd_ports clock_rtl]

# 11) Подаём внешний reset (предположим, активный высокий) на proc_sys_reset
connect_bd_net [get_bd_pins sys_reset_0/ext_reset_in] [get_bd_ports reset_rtl]

# 12) Соединяем выходы clk_wiz -> proc_sys_reset
connect_bd_net [get_bd_pins sys_clk_0/clk_out1] [get_bd_pins sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins sys_clk_0/locked]   [get_bd_pins sys_reset_0/dcm_locked]

# 13) Такт/сброс на Interconnect
connect_bd_net [get_bd_pins sys_clk_0/clk_out1]             [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]

connect_bd_net [get_bd_pins sys_clk_0/clk_out1] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins sys_clk_0/clk_out1] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins sys_clk_0/clk_out1] [get_bd_pins axi_interconnect_0/M01_ACLK]

# 14) Такт/сброс на umdom_TOP (AXI Slave)
connect_bd_net [get_bd_pins sys_clk_0/clk_out1]             [get_bd_pins umdom_TOP_0/S_AXI_ACLK]
connect_bd_net [get_bd_pins sys_reset_0/peripheral_aresetn] [get_bd_pins umdom_TOP_0/S_AXI_ARESETN]

# 15) Такт/сброс на AXI BRAM Controller
connect_bd_net [get_bd_pins sys_clk_0/clk_out1]             [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins sys_reset_0/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

#
# ===== AXI Interconnect: MasterPort -> Slaves (umdom_TOP, axi_bram_ctrl) =====
#

# 16) Подключаем внешний Master (S00_AXI) к входу Interconnect
connect_bd_intf_net [get_bd_intf_port S00_AXI] \
                    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# 17) Подключаем выход Interconnect M00_AXI к umdom_TOP_0 (S_AXI)
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
                    [get_bd_intf_pins umdom_TOP_0/S_AXI]

# 18) Подключаем выход Interconnect M01_AXI к AXI BRAM Controller
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] \
                    [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

#
# ===== Соединяем AXI BRAM Controller с blk_mem_gen =====
#
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] \
                    [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

#
# ===== Подключаем пользовательские сигналы (температура/окно) к umdom_TOP =====
#
connect_bd_net [get_bd_ports temp_sensor_in]     [get_bd_pins umdom_TOP_0/temp_sensor_in]
connect_bd_net [get_bd_ports temp_valid]         [get_bd_pins umdom_TOP_0/temp_valid]
connect_bd_net [get_bd_ports window_position]    [get_bd_pins umdom_TOP_0/window_position]
connect_bd_net [get_bd_ports window_busy]        [get_bd_pins umdom_TOP_0/window_busy]
connect_bd_net [get_bd_ports window_control]     [get_bd_pins umdom_TOP_0/window_control]

#
# ===== Сохраняем дизайн, создаём wrapper =====
#
save_bd_design

make_wrapper -files [get_files design_1.bd] -top -force
add_files -norecurse [glob -nocomplain design_1_wrapper.*]

update_compile_order -fileset sources_1

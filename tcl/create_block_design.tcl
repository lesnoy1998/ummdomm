create_bd_design "design_umdom"
update_compile_order -fileset sources_1
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
create_bd_cell -type ip -vlnv SUAI:STUDENT:ip_block_axi:1.0 ip_block_axi_0
set_property -dict [list CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells blk_mem_gen_0]
set_property -dict [list CONFIG.DATA_WIDTH {64} CONFIG.PROTOCOL {AXI4} CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
create_bd_port -dir I -type clk -freq_hz 250000000 refclk
create_bd_port -dir I -type rst sys_rst_n
connect_bd_net [get_bd_ports sys_rst_n] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_ports refclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]


create_bd_port -dir I -from 11 -to 0 -type data temp_sensor_in
create_bd_port -dir I -type data temp_valid
create_bd_port -dir I -from 7 -to 0 -type data window_position
create_bd_port -dir O -from 1 -to 0 -type data window_control
create_bd_port -dir I -type data window_busy

connect_bd_net [get_bd_ports refclk] [get_bd_pins ip_block_axi_0/m_axi_aclk]
connect_bd_net [get_bd_ports sys_rst_n] [get_bd_pins ip_block_axi_0/m_axi_aresetn]
connect_bd_intf_net [get_bd_intf_pins ip_block_axi_0/M_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

connect_bd_net [get_bd_ports temp_sensor_in] [get_bd_pins ip_block_axi_0/temp_sensor_in]
connect_bd_net [get_bd_ports temp_valid] [get_bd_pins ip_block_axi_0/temp_valid]
connect_bd_net [get_bd_ports window_position] [get_bd_pins ip_block_axi_0/window_position]
connect_bd_net [get_bd_ports window_control] [get_bd_pins ip_block_axi_0/window_control]
connect_bd_net [get_bd_ports window_busy] [get_bd_pins ip_block_axi_0/window_busy]

make_wrapper -files [get_files $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.srcs/sources_1/bd/design_umdom/design_umdom.bd] -top
add_files -norecurse $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.gen/sources_1/bd/design_umdom/hdl/design_umdom_wrapper.vhd
update_compile_order -fileset sources_1
regenerate_bd_layout

set_property synth_checkpoint_mode None [get_files  $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.srcs/sources_1/bd/design_umdom/design_umdom.bd]
generate_target all [get_files  $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.srcs/sources_1/bd/design_umdom/design_umdom.bd]
export_ip_user_files -of_objects [get_files $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.srcs/sources_1/bd/design_umdom/design_umdom.bd] -no_script -sync -force -quiet
export_simulation -of_objects [get_files $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.srcs/sources_1/bd/design_umdom/design_umdom.bd] -directory /$CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.ip_user_files/sim_scripts -ip_user_files_dir $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.ip_user_files -ipstatic_source_dir $CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.ip_user_files/ipstatic -lib_map_path [list {xcelium=$CURRENT_DIR/$PROJECT_NAME/$PROJECT_NAME.cache/compile_simlib/xcelium} ] -use_ip_compiled_libs -force -quiet

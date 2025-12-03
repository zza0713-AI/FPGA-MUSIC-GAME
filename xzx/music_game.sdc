# 时钟约束
create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]

# 输入延迟约束
set_input_delay -clock clk_50m 5 [get_ports {rst_n}]
set_input_delay -clock clk_50m 5 [get_ports {f_keys[*]}]
set_input_delay -clock clk_50m 5 [get_ports {sw[*]}]
set_input_delay -clock clk_50m 5 [get_ports {start_btn}]

# 输出延迟约束
set_output_delay -clock clk_50m 5 [get_ports {led_row[*]}]
set_output_delay -clock clk_50m 5 [get_ports {led_col[*]}]
set_output_delay -clock clk_50m 5 [get_ports {seg_select[*]}]
set_output_delay -clock clk_50m 5 [get_ports {seg_data[*]}]
set_output_delay -clock clk_50m 5 [get_ports {audio_pwm}]
set_output_delay -clock clk_50m 5 [get_ports {led_hit[*]}]
set_output_delay -clock clk_50m 5 [get_ports {led_status[*]}]
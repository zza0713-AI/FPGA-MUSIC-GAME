# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

# Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Full Version
# File: D:\C-Workspace\VLSI-Experiments\grad\video_player.tcl
# Generated on: Wed Nov 19 18:38:46 2025

package require ::quartus::project

set_location_assignment PIN_T1 -to clk
set_location_assignment PIN_C3 -to col_sel[3]
set_location_assignment PIN_C15 -to col_sel[2]
set_location_assignment PIN_F13 -to col_sel[1]
set_location_assignment PIN_C13 -to col_sel[0]
set_location_assignment PIN_B7 -to col_data[15]
set_location_assignment PIN_C6 -to col_data[14]
set_location_assignment PIN_A8 -to col_data[13]
set_location_assignment PIN_C7 -to col_data[12]
set_location_assignment PIN_C8 -to col_data[11]
set_location_assignment PIN_F8 -to col_data[10]
set_location_assignment PIN_F10 -to col_data[9]
set_location_assignment PIN_F11 -to col_data[8]
set_location_assignment PIN_E12 -to col_data[7]
set_location_assignment PIN_B10 -to col_data[6]
set_location_assignment PIN_A10 -to col_data[5]
set_location_assignment PIN_B13 -to col_data[4]
set_location_assignment PIN_B14 -to col_data[3]
set_location_assignment PIN_A16 -to col_data[2]
set_location_assignment PIN_B16 -to col_data[1]
set_location_assignment PIN_B17 -to col_data[0]
set_location_assignment PIN_P20 -to seg[0]
set_location_assignment PIN_R20 -to seg[1]
set_location_assignment PIN_R17 -to seg[2]
set_location_assignment PIN_P22 -to seg[3]
set_location_assignment PIN_R21 -to seg[4]
set_location_assignment PIN_T17 -to seg[5]
set_location_assignment PIN_R22 -to seg[6]
set_location_assignment PIN_U21 -to seg[7]
set_location_assignment PIN_AA17 -to sel[3]
set_location_assignment PIN_AB16 -to sel[2]
set_location_assignment PIN_AB17 -to sel[1]
set_location_assignment PIN_T18 -to sel[0]
set_location_assignment PIN_AB14 -to f_keys[0]
set_location_assignment PIN_W20 -to f_keys[1]
set_location_assignment PIN_AA15 -to f_keys[2]
set_location_assignment PIN_AB15 -to f_keys[3]
set_location_assignment PIN_T15 -to f_keys[4]
set_location_assignment PIN_U20 -to rst_n_key
set_location_assignment PIN_M16 -to sw_switches[0]
set_location_assignment PIN_R19 -to sw_switches[1]
set_location_assignment PIN_AA14 -to sw_switches[2]
set_location_assignment PIN_AA1 -to sw_switches[3]
set_location_assignment PIN_A3 -to sw_switches[4]
set_location_assignment PIN_B4 -to sw_switches[5]
set_location_assignment PIN_N19 -to computer_out
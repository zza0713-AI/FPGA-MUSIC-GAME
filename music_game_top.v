`timescale 1ns / 1ps

/**
 * FPGA Music Game - Top Level Module
 * EP4CE115F23C7 FPGA
 * Author: Zhang Zhiang
 * Date: 2025-11-30
 */

module music_game_top(
    input clk,                          // 50MHz system clock
    input rst_n,                        // Reset (active low)
    
    // Button inputs
    input [9:0] f_keys,                 // F1~F10 buttons
    input [15:0] sw_switches,           // SW1~SW16 switches
    
    // LED matrix output (16x16)
    output [15:0] led_row,              // Row scan signal
    output [15:0] led_col,              // Column drive signal
    
    // 7-segment display output (8-digit)
    output [7:0] seg_select,            // Digit select signal
    output [6:0] seg_data               // Segment drive signal (a-g)
);

    // Internal signals
    wire clk_refresh;                   // Block fall clock
    wire clk_scan;                      // Matrix scan clock
    wire clk_seg;                       // Segment scan clock
    
    wire [31:0] score;                  // Score value
    wire game_state;                    // Game state (0=run, 1=pause)
    
    wire [3:0] block_array [15:0];      // 4 columns x 16 rows block matrix
    
    // ============ Clock Divider ============
    clock_divider clk_div_inst(
        .clk(clk),
        .rst_n(rst_n),
        .difficulty(sw_switches[3:0]),
        .clk_refresh(clk_refresh),
        .clk_scan(clk_scan),
        .clk_seg(clk_seg)
    );
    
    // ============ Game Controller ============
    game_controller game_ctrl_inst(
        . clk(clk),
        .rst_n(rst_n),
        .clk_refresh(clk_refresh),
        .f_key_pause(f_keys[4]),         // F5: pause/resume
        .f_key_reset(f_keys[5]),         // F6: reset
        . game_state(game_state)
    );
    
    // ============ Block Manager (ROM mode) ============
    block_manager_rom block_mgr_inst(
        .clk(clk),
        . rst_n(rst_n),
        .clk_refresh(clk_refresh),
        .game_state(game_state),
        .f_key_hit(f_keys[3:0]),         // F1~F4
        .sw_difficulty(sw_switches[3:0]),
        .chart_select(sw_switches[5:4]),
        .block_array(block_array),
        .score(score)
    );
    
    // ============ LED Matrix Driver ============
    led_matrix_driver led_drv_inst(
        .clk(clk),
        . clk_scan(clk_scan),
        .rst_n(rst_n),
        .block_array(block_array),
        .led_row(led_row),
        .led_col(led_col)
    );
    
    // ============ 7-Segment Display Driver ============
    segment_display seg_drv_inst(
        .clk(clk),
        .clk_seg(clk_seg),
        .rst_n(rst_n),
        .score(score),
        .seg_select(seg_select),
        .seg_data(seg_data)
    );

endmodule

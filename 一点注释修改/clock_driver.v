`timescale 1ns / 1ps

/**
 * Clock Divider Module
 * 产生不同频率的时钟信号
 */

module clock_divider(
    input clk,                          // 25MHz 系统时钟
    input rst_n,
    input [3:0] difficulty,             // 难度等级 0-15
    output reg [31:0] refresh_max,      // 方块下落时钟使能信号 (1-10Hz)
    output reg clk_scan                 // 矩阵扫描时钟 (~1kHz)
);

    // ============ 方块下落时钟 ============
    // 依据难度选择不同速度
    // 0: 1Hz, 1: 1.5Hz, .. ., 15: 10Hz
    reg [31:0] refresh_cnt;
    
    always @(*) begin
        case(difficulty)
            4'd0:  refresh_max = 50_000_000;   // 1Hz
            4'd1:  refresh_max = 33_333_333;   // 1.5Hz
            4'd2:  refresh_max = 25_000_000;   // 2Hz
            4'd3:  refresh_max = 20_000_000;   // 2.5Hz
            4'd4:  refresh_max = 16_666_666;   // 3Hz
            4'd5:  refresh_max = 14_285_714;   // 3.5Hz
            4'd6:  refresh_max = 12_500_000;   // 4Hz
            4'd7:  refresh_max = 11_111_111;   // 4.5Hz
            4'd8:  refresh_max = 10_000_000;   // 5Hz
            4'd9:  refresh_max = 9_090_909;    // 5.5Hz
            4'd10: refresh_max = 8_333_333;    // 6Hz
            4'd11: refresh_max = 7_692_307;    // 6. 5Hz
            4'd12: refresh_max = 7_142_857;    // 7Hz
            4'd13: refresh_max = 6_666_666;    // 7.5Hz
            4'd14: refresh_max = 6_250_000;    // 8Hz
            default: refresh_max = 5_000_000;  // 10Hz (max)
        endcase
    end
    /*
    always @(posedge clk or negedge rst_n) begin
        if(! rst_n) begin
            refresh_cnt <= 32'd0;
            clk_refresh <= 1'b0;
        end
        else begin
            if(refresh_cnt >= refresh_max) begin
                refresh_cnt <= 32'd0;
                clk_refresh <= ~clk_refresh;
            end
            else begin
                refresh_cnt <= refresh_cnt + 1;
            end
        end
    end
    */
    // ============ Matrix Scan Clock (~1kHz) ============
    reg [16:0] scan_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            scan_cnt <= 17'd0;
            clk_scan <= 1'b0;
        end
        else begin
            if(scan_cnt >= 17'd25_000) begin   // 25MHz / 25000 = 1kHz
                scan_cnt <= 17'd0;
                clk_scan <= ~clk_scan;
            end
            else begin
                scan_cnt <= scan_cnt + 1;
            end
        end
    end

endmodule

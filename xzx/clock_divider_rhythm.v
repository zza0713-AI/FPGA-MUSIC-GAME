`timescale 1ns / 1ps

module clock_divider_rhythm(
    input clk_50m,
    input rst_n,
    input [2:0] difficulty,
    output reg clk_audio,      // 44.1kHz音频时钟
    output reg clk_refresh,    // 音符下落速度
    output reg clk_scan,       // LED扫描时钟
    output reg clk_seg         // 数码管扫描时钟
);

    // ============ 44.1kHz音频时钟 ============
    reg [10:0] audio_cnt;
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            audio_cnt <= 11'd0;
            clk_audio <= 1'b0;
        end
        else begin
            if(audio_cnt >= 11'd1134) begin  // 50MHz / 1134 ≈ 44.1kHz
                audio_cnt <= 11'd0;
                clk_audio <= ~clk_audio;
            end
            else begin
                audio_cnt <= audio_cnt + 1;
            end
        end
    end
    
    // ============ 音符下落速度 ============
    reg [31:0] refresh_cnt;
    reg [31:0] refresh_max;
    
    always @(*) begin
        case(difficulty)
            3'b000: refresh_max = 32'd5_000_000;    // 10Hz (简单)
            3'b001: refresh_max = 32'd2_500_000;    // 20Hz (普通)
            3'b010: refresh_max = 32'd1_250_000;    // 40Hz (困难)
            3'b011: refresh_max = 32'd625_000;      // 80Hz (专家)
            default: refresh_max = 32'd2_500_000;   // 默认普通
        endcase
    end
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
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
    
    // ============ LED扫描时钟 (1kHz) ============
    reg [16:0] scan_cnt;
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            scan_cnt <= 17'd0;
            clk_scan <= 1'b0;
        end
        else begin
            if(scan_cnt >= 17'd25_000) begin  // 50MHz / 25000 = 2kHz
                scan_cnt <= 17'd0;
                clk_scan <= ~clk_scan;
            end
            else begin
                scan_cnt <= scan_cnt + 1;
            end
        end
    end
    
    // ============ 数码管扫描时钟 (500Hz) ============
    reg [17:0] seg_cnt;
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            seg_cnt <= 18'd0;
            clk_seg <= 1'b0;
        end
        else begin
            if(seg_cnt >= 18'd50_000) begin  // 50MHz / 50000 = 1kHz
                seg_cnt <= 18'd0;
                clk_seg <= ~clk_seg;
            end
            else begin
                seg_cnt <= seg_cnt + 1;
            end
        end
    end

endmodule
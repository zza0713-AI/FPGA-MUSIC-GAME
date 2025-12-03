`timescale 1ns / 1ps

module seg_display_rhythm(
    input clk,
    input rst_n,
    input [31:0] score,
    input [3:0] combo,
    input [7:0] accuracy,
    input [3:0] game_mode,
    
    output reg [7:0] seg_select,
    output reg [6:0] seg_data
);

    reg [2:0] digit_cnt;
    reg [3:0] digit_value;
    
    // ============ 位选信号 ============
    always @(*) begin
        case(digit_cnt)
            3'd0: seg_select = 8'b1111_1110;  // 连击
            3'd1: seg_select = 8'b1111_1101;  // 准确率
            3'd2: seg_select = 8'b1111_1011;  // 分数
            3'd3: seg_select = 8'b1111_0111;
            3'd4: seg_select = 8'b1110_1111;
            3'd5: seg_select = 8'b1101_1111;
            3'd6: seg_select = 8'b1011_1111;  // 难度
            3'd7: seg_select = 8'b0111_1111;  // 模式
        endcase
    end
    
    // ============ 显示内容选择 ============
    always @(*) begin
        case(digit_cnt)
            3'd0: digit_value = combo;
            3'd1: digit_value = accuracy[7:4];
            3'd2: digit_value = (score / 10000) % 10;
            3'd3: digit_value = (score / 1000) % 10;
            3'd4: digit_value = (score / 100) % 10;
            3'd5: digit_value = (score / 10) % 10;
            3'd6: digit_value = game_mode;
            3'd7: digit_value = 4'd0;
        endcase
    end
    
    // ============ 7段译码器 ============
    always @(*) begin
        case(digit_value)
            4'd0:  seg_data = 7'b011_1111;
            4'd1:  seg_data = 7'b000_0110;
            4'd2:  seg_data = 7'b101_1011;
            4'd3:  seg_data = 7'b100_1111;
            4'd4:  seg_data = 7'b110_0110;
            4'd5:  seg_data = 7'b110_1101;
            4'd6:  seg_data = 7'b111_1101;
            4'd7:  seg_data = 7'b000_0111;
            4'd8:  seg_data = 7'b111_1111;
            4'd9:  seg_data = 7'b110_1111;
            default: seg_data = 7'b000_0000;
        endcase
    end
    
    // ============ 数码管扫描计数器 ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            digit_cnt <= 3'd0;
        end
        else begin
            digit_cnt <= digit_cnt + 1;
            if(digit_cnt >= 3'd7) begin
                digit_cnt <= 3'd0;
            end
        end
    end

endmodule
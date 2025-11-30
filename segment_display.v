`timescale 1ns / 1ps

/**
 * Segment Display Driver - 8-Digit 7-Segment Display
 * Shows game score in decimal format
 */

module segment_display(
    input clk,
    input clk_seg,
    input rst_n,
    input [31:0] score,                 // 8-digit score (0-99999999)
    
    output reg [7:0] seg_select,        // Digit select signal
    output reg [6:0] seg_data           // Segment output (a-g)
);

    reg [2:0] digit_cnt;                // Current digit being scanned (0-7)
    reg [3:0] digit_value;              // Current digit value (0-9)
    reg [31:0] score_bcd;               // BCD-coded score
    
    // ============ Digit Select Signal ============
    always @(*) begin
        case(digit_cnt)
            3'd0: seg_select = 8'b1111_1110;  // Digit 0
            3'd1: seg_select = 8'b1111_1101;  // Digit 1
            3'd2: seg_select = 8'b1111_1011;  // Digit 2
            3'd3: seg_select = 8'b1111_0111;  // Digit 3
            3'd4: seg_select = 8'b1110_1111;  // Digit 4
            3'd5: seg_select = 8'b1101_1111;  // Digit 5
            3'd6: seg_select = 8'b1011_1111;  // Digit 6
            3'd7: seg_select = 8'b0111_1111;  // Digit 7
            default: seg_select = 8'b1111_1111;
        endcase
    end
    
    // ============ Decimal to BCD Conversion ============
    always @(*) begin
        score_bcd[3:0]   = score % 10;
        score_bcd[7:4]   = (score / 10) % 10;
        score_bcd[11:8]  = (score / 100) % 10;
        score_bcd[15:12] = (score / 1000) % 10;
        score_bcd[19:16] = (score / 10000) % 10;
        score_bcd[23:20] = (score / 100000) % 10;
        score_bcd[27:24] = (score / 1000000) % 10;
        score_bcd[31:28] = (score / 10000000) % 10;
    end
    
    // ============ Extract Current Digit ============
    always @(*) begin
        case(digit_cnt)
            3'd0: digit_value = score_bcd[3:0];
            3'd1: digit_value = score_bcd[7:4];
            3'd2: digit_value = score_bcd[11:8];
            3'd3: digit_value = score_bcd[15:12];
            3'd4: digit_value = score_bcd[19:16];
            3'd5: digit_value = score_bcd[23:20];
            3'd6: digit_value = score_bcd[27:24];
            3'd7: digit_value = score_bcd[31:28];
            default: digit_value = 4'd0;
        endcase
    end
    
    // ============ 7-Segment Decoder ============
    // Segments: a b c d e f g
    //           0 1 2 3 4 5 6
    always @(*) begin
        case(digit_value)
            4'd0:  seg_data = 7'b0111_111;  // 0
            4'd1:  seg_data = 7'b0000_110;  // 1
            4'd2:  seg_data = 7'b1011_011;  // 2
            4'd3:  seg_data = 7'b1001_111;  // 3
            4'd4:  seg_data = 7'b1100_110;  // 4
            4'd5:  seg_data = 7'b1101_101;  // 5
            4'd6:  seg_data = 7'b1111_101;  // 6
            4'd7:  seg_data = 7'b0000_111;  // 7
            4'd8:  seg_data = 7'b1111_111;  // 8
            4'd9:  seg_data = 7'b1101_111;  // 9
            default: seg_data = 7'b0000_000; // Off
        endcase
    end
    
    // ============ Digit Counter ============
    always @(posedge clk_seg or negedge rst_n) begin
        if(!rst_n) begin
            digit_cnt <= 3'd0;
        end
        else begin
            if(digit_cnt >= 3'd7) begin
                digit_cnt <= 3'd0;
            end
            else begin
                digit_cnt <= digit_cnt + 1;
            end
        end
    end

endmodule

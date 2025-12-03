`timescale 1ns / 1ps

module led_matrix_rhythm(
    input clk,
    input clk_scan,
    input rst_n,
    input [3:0] note_columns [15:0],
    input [3:0] hit_leds,
    
    output reg [15:0] led_row,
    output reg [15:0] led_col
);

    reg [3:0] scan_row;
    wire [3:0] current_note;
    
    // ============ 行扫描 ============
    always @(posedge clk_scan or negedge rst_n) begin
        if(!rst_n) begin
            scan_row <= 4'b0;
        end
        else begin
            if(scan_row >= 4'd15) begin
                scan_row <= 4'b0;
            end
            else begin
                scan_row <= scan_row + 1;
            end
        end
    end
    
    // ============ 行选择信号 ============
    always @(*) begin
        case(scan_row)
            4'd0:  led_row = 16'b1111_1111_1111_1110;
            4'd1:  led_row = 16'b1111_1111_1111_1101;
            4'd2:  led_row = 16'b1111_1111_1111_1011;
            4'd3:  led_row = 16'b1111_1111_1111_0111;
            4'd4:  led_row = 16'b1111_1111_1110_1111;
            4'd5:  led_row = 16'b1111_1111_1101_1111;
            4'd6:  led_row = 16'b1111_1111_1011_1111;
            4'd7:  led_row = 16'b1111_1111_0111_1111;
            4'd8:  led_row = 16'b1111_1110_1111_1111;
            4'd9:  led_row = 16'b1111_1101_1111_1111;
            4'd10: led_row = 16'b1111_1011_1111_1111;
            4'd11: led_row = 16'b1111_0111_1111_1111;
            4'd12: led_row = 16'b1110_1111_1111_1111;
            4'd13: led_row = 16'b1101_1111_1111_1111;
            4'd14: led_row = 16'b1011_1111_1111_1111;
            4'd15: led_row = 16'b0111_1111_1111_1111;
            default: led_row = 16'b1111_1111_1111_1111;
        endcase
    end
    
    // ============ 列驱动 ============
    assign current_note = note_columns[scan_row];
    
    always @(*) begin
        led_col = 16'b0;
        
        // 正常音符显示
        if(current_note[0]) led_col[2] = 1'b1;
        if(current_note[1]) led_col[6] = 1'b1;
        if(current_note[2]) led_col[10] = 1'b1;
        if(current_note[3]) led_col[14] = 1'b1;
        
        // 击中反馈
        if(scan_row == 4'd15) begin
            if(hit_leds[0]) led_col[3] = 1'b1;
            if(hit_leds[1]) led_col[7] = 1'b1;
            if(hit_leds[2]) led_col[11] = 1'b1;
            if(hit_leds[3]) led_col[15] = 1'b1;
        end
    end

endmodule
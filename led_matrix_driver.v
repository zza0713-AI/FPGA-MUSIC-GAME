`timescale 1ns / 1ps

/**
 * LED Matrix Driver - 16x16 Display
 * Maps game blocks to LED matrix output
 */

module led_matrix_driver(
    input clk,
    input clk_scan,
    input rst_n,
    input [3:0] block_array [15:0],     // 4 columns x 16 rows
    
    output reg [15:0] led_row,          // Row scan signal
    output reg [15:0] led_col           // Column drive signal
);

    reg [3:0] scan_row;                 // Current scan row (0-15)
    
    // ============ Row Counter ============
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
    
    // ============ Row Scan Signal (Active Low) ============
    always @(scan_row) begin
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
    
    // ============ Column Drive Signal ============
    // Map 4 game columns to 16 LED columns:
    // Column 0 -> LED[2:3]
    // Column 1 -> LED[6:7]
    // Column 2 -> LED[10:11]
    // Column 3 -> LED[14:15]
    
    always @(scan_row or block_array) begin
        led_col = 16'b0;
        
        if(block_array[scan_row][0]) begin  // Column 0
            led_col[2] = 1'b1;
            led_col[3] = 1'b1;
        end
        
        if(block_array[scan_row][1]) begin  // Column 1
            led_col[6] = 1'b1;
            led_col[7] = 1'b1;
        end
        
        if(block_array[scan_row][2]) begin  // Column 2
            led_col[10] = 1'b1;
            led_col[11] = 1'b1;
        end
        
        if(block_array[scan_row][3]) begin  // Column 3
            led_col[14] = 1'b1;
            led_col[15] = 1'b1;
        end
    end

endmodule

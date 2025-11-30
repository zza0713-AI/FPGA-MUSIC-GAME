`timescale 1ns / 1ps

/**
 * Random Number Generator - LFSR
 * Generates pseudo-random column selection for random mode
 */

module random_gen(
    input clk,
    input rst_n,
    output reg [3:0] random_col         // Random column 0-3
);

    // Linear Feedback Shift Register (LFSR)
    reg [15:0] lfsr;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lfsr <= 16'hACE1;  // Initial seed
        end
        else begin
            // Polynomial: x^16 + x^14 + x^13 + x^11 + 1
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end
    
    // Extract random column
    always @(*) begin
        random_col = lfsr[3:0] % 4;
    end

endmodule

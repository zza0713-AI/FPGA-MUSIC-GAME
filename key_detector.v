`timescale 1ns / 1ps

/**
 * Key Detector - Button Debouncing
 * Detects clean button presses for F1-F4
 */

module key_detector(
    input clk,
    input rst_n,
    input [3:0] f_keys_in,              // F1-F4 raw input
    output reg [3:0] f_keys_out         // Debounced output
);

    // Debounce counters for each button
    reg [19:0] deb_cnt [3:0];
    reg [3:0] key_pressed_prev;
    
    integer i;
    
    // ============ Debouncing Logic ============
    always @(posedge clk or negedge rst_n) begin
        if(! rst_n) begin
            for(i = 0; i < 4; i = i + 1) begin
                deb_cnt[i] <= 20'd0;
                f_keys_out[i] <= 1'b0;
            end
            key_pressed_prev <= 4'b0;
        end
        else begin
            for(i = 0; i < 4; i = i + 1) begin
                if(f_keys_in[i] != key_pressed_prev[i]) begin
                    deb_cnt[i] <= 20'd0;
                end
                else if(deb_cnt[i] < 20'd500_000) begin  // ~10ms delay
                    deb_cnt[i] <= deb_cnt[i] + 1;
                end
                else begin
                    f_keys_out[i] <= f_keys_in[i];
                end
            end
            key_pressed_prev <= f_keys_in;
        end
    end

endmodule

`timescale 1ns / 1ps

/**
 * Game Controller - State Machine
 * Manages game states and transitions
 */

module game_controller(
    input clk,
    input rst_n,
    input clk_refresh,
    input f_key_pause,                  // F5: pause/resume
    input f_key_reset,                  // F6: reset
    output reg game_state               // 0=running, 1=paused
);

    // Debounce counters
    reg [19:0] pause_deb_cnt;
    reg [19:0] reset_deb_cnt;
    reg pause_pressed_prev;
    reg reset_pressed_prev;
    reg pause_edge;
    reg reset_edge;
    
    // ============ Debouncing Logic ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pause_deb_cnt <= 20'd0;
            reset_deb_cnt <= 20'd0;
            pause_pressed_prev <= 1'b0;
            reset_pressed_prev <= 1'b0;
        end
        else begin
            // F5 debounce
            if(f_key_pause != pause_pressed_prev) begin
                pause_deb_cnt <= 20'd0;
            end
            else if(pause_deb_cnt < 20'd500_000) begin  // ~10ms delay
                pause_deb_cnt <= pause_deb_cnt + 1;
            end
            else begin
                pause_pressed_prev <= f_key_pause;
            end
            
            // F6 debounce
            if(f_key_reset != reset_pressed_prev) begin
                reset_deb_cnt <= 20'd0;
            end
            else if(reset_deb_cnt < 20'd500_000) begin
                reset_deb_cnt <= reset_deb_cnt + 1;
            end
            else begin
                reset_pressed_prev <= f_key_reset;
            end
        end
    end
    
    // ============ Edge Detection ============
    reg pause_pressed_reg;
    reg reset_pressed_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pause_pressed_reg <= 1'b0;
            reset_pressed_reg <= 1'b0;
            pause_edge <= 1'b0;
            reset_edge <= 1'b0;
        end
        else begin
            pause_edge <= pause_pressed_prev & ~pause_pressed_reg;
            reset_edge <= reset_pressed_prev & ~reset_pressed_reg;
            
            pause_pressed_reg <= pause_pressed_prev;
            reset_pressed_reg <= reset_pressed_prev;
        end
    end
    
    // ============ State Transition ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            game_state <= 1'b0;  // Start in running state
        end
        else begin
            if(reset_edge) begin
                game_state <= 1'b0;  // Reset to running
            end
            else if(pause_edge) begin
                game_state <= ~game_state;  // Toggle pause/run
            end
        end
    end

endmodule

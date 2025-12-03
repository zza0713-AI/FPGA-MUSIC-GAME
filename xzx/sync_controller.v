`timescale 1ns / 1ps

module sync_controller(
    input clk,
    input rst_n,
    input game_start,
    input [3:0] difficulty,
    
    output reg game_active,
    output reg beat_pulse,
    output reg [3:0] current_beat,
    output reg [15:0] audio_addr,
    output reg [15:0] beat_addr
);

    // ============ 100ms时钟生成 ============
    parameter BEAT_DIV = 5_000_000;
    reg [31:0] beat_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            beat_counter <= 32'd0;
            beat_pulse <= 1'b0;
        end
        else if(game_active) begin
            if(beat_counter >= BEAT_DIV) begin
                beat_counter <= 32'd0;
                beat_pulse <= 1'b1;
            end
            else begin
                beat_counter <= beat_counter + 1;
                beat_pulse <= 1'b0;
            end
        end
        else begin
            beat_pulse <= 1'b0;
        end
    end
    
    // ============ 游戏状态机 ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            game_active <= 1'b0;
            audio_addr <= 16'd0;
            beat_addr <= 16'd0;
            current_beat <= 4'b0;
        end
        else begin
            if(game_start && !game_active) begin
                game_active <= 1'b1;
                audio_addr <= 16'd0;
                beat_addr <= 16'd0;
                current_beat <= 4'b0;
            end
            
            if(game_active) begin
                if(beat_pulse) begin
                    beat_addr <= beat_addr + 1;
                end
                
                if(beat_addr >= 16'd1200) begin
                    game_active <= 1'b0;
                end
            end
        end
    end

endmodule
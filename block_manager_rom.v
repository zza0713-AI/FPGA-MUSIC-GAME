`timescale 1ns / 1ps

/**
 * Block Manager - ROM Mode
 * Loads note patterns from ROM (converted MIDI charts)
 */

module block_manager_rom(
    input clk,
    input rst_n,
    input clk_refresh,
    input game_state,                   // 0=running, 1=paused
    input [3:0] f_key_hit,              // F1-F4 hit signals
    input [3:0] sw_difficulty,
    input [1:0] chart_select,           // Select which chart (0-3)
    
    output reg [3:0] block_array [15:0],
    output reg [31:0] score
);

    reg [15:0] chart_address;           // Current ROM read address
    wire [3:0] chart_data;              // Data from ROM
    reg [3:0] block_array_next [15:0];
    reg [31:0] score_next;
    
    integer row, col;
    reg [3:0] hit_flags;
    
    // ============ Chart ROM Instances ============
    // You would instantiate your generated ROM modules here
    // Example: chart_rom_easy, chart_rom_normal, chart_rom_hard
    
    chart_rom_easy chart_easy(
        .addr(chart_address),
        . data(chart_data)
    );
    
    // Note: In practice, you'd have logic to select between different ROM instances
    // For now, we default to easy mode
    
    // ============ Initialization ============
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            score <= 32'd0;
            chart_address <= 16'd0;
            for(i = 0; i < 16; i = i + 1) begin
                block_array[i] <= 4'b0;
            end
        end
        else begin
            score <= score_next;
            for(i = 0; i < 16; i = i + 1) begin
                block_array[i] <= block_array_next[i];
            end
        end
    end
    
    // ============ Block Fall Logic ============
    always @(posedge clk_refresh or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 16; i = i + 1) begin
                block_array_next[i] <= 4'b0;
            end
            score_next <= 32'd0;
            chart_address <= 16'd0;
            hit_flags <= 4'b0;
        end
        else if(game_state == 1'b0) begin  // Running
            
            // 1.  Detect hits
            hit_flags = 4'b0;
            for(col = 0; col < 4; col = col + 1) begin
                if(f_key_hit[col] && block_array[15][col]) begin
                    hit_flags[col] = 1'b1;
                    score_next = score + 1;
                end
            end
            
            // 2.  Shift blocks down
            for(row = 15; row > 0; row = row - 1) begin
                for(col = 0; col < 4; col = col + 1) begin
                    if(hit_flags[col] && row == 15) begin
                        block_array_next[row][col] = 1'b0;
                    end
                    else begin
                        block_array_next[row][col] = block_array[row-1][col];
                    end
                end
            end
            
            // 3. Load new row from ROM
            for(col = 0; col < 4; col = col + 1) begin
                block_array_next[0][col] = chart_data[col];
            end
            
            // 4.  Increment address
            if(chart_address < 16'd65535) begin
                chart_address <= chart_address + 1;
            end
            else begin
                chart_address <= 16'd0;  // Loop
            end
            
        end
        else begin  // Paused
            for(i = 0; i < 16; i = i + 1) begin
                block_array_next[i] = block_array[i];
            end
            score_next = score;
        end
    end

endmodule

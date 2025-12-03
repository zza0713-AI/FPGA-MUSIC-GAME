`timescale 1ns / 1ps

module note_generator(
    input clk,                 // 游戏刷新时钟
    input rst_n,
    input game_active,
    input [3:0] difficulty,
    input note_valid,         // 新音符信号
    input [3:0] new_note,     // 新音符数据
    
    output reg [3:0] note_columns [15:0]  // 音符矩阵
);

    reg [3:0] note_buffer [15:0];
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<16; i=i+1) begin
                note_columns[i] <= 4'b0;
                note_buffer[i] <= 4'b0;
            end
        end
        else if(game_active) begin
            // 1. 所有音符下移一行
            for(i=15; i>0; i=i-1) begin
                note_buffer[i] <= note_columns[i-1];
            end
            
            // 2. 顶部插入新音符
            if(note_valid) begin
                note_buffer[0] <= new_note;
            end
            else begin
                note_buffer[0] <= 4'b0;
            end
            
            // 3. 更新输出
            for(i=0; i<16; i=i+1) begin
                note_columns[i] <= note_buffer[i];
            end
        end
        else begin
            for(i=0; i<16; i=i+1) begin
                note_columns[i] <= 4'b0;
            end
        end
    end

endmodule
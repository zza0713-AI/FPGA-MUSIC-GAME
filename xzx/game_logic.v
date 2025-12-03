`timescale 1ns / 1ps

module game_logic(
    input clk,
    input rst_n,
    input game_active,
    input [3:0] f_keys,        // 玩家按键输入
    input [3:0] bottom_row,    // 最底行音符
    input hit_accuracy,        // 精度判定开关
    
    output reg [31:0] score,   // 得分
    output reg [3:0] combo,    // 连击数
    output reg [7:0] accuracy, // 准确率
    output reg [3:0] hit_indicator  // 击中指示灯
);

    // ============ 击中判定参数 ============
    parameter PERFECT_WINDOW = 5;   // 完美窗口（毫秒）
    parameter GOOD_WINDOW = 10;     // 良好窗口
    parameter MISS_THRESHOLD = 20;  // 错过阈值
    
    // ============ 状态寄存器 ============
    reg [3:0] key_pressed;
    reg [15:0] note_timer [3:0];
    reg [3:0] note_active;
    reg [3:0] hit_result;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            score <= 32'd0;
            combo <= 4'd0;
            accuracy <= 8'd100;
            hit_indicator <= 4'b0;
            
            for(i=0; i<4; i=i+1) begin
                note_timer[i] <= 16'd0;
            end
        end
        else if(game_active) begin
            note_active <= bottom_row;
            hit_indicator <= 4'b0;
            hit_result <= 4'b0;
            
            for(i=0; i<4; i=i+1) begin
                if(note_active[i]) begin
                    note_timer[i] <= note_timer[i] + 1;
                    
                    if(f_keys[i]) begin
                        if(note_timer[i] < PERFECT_WINDOW) begin
                            score <= score + 100;
                            combo <= combo + 1;
                            hit_result[i] <= 1'b1;
                            hit_indicator[i] <= 1'b1;
                        end
                        else if(note_timer[i] < GOOD_WINDOW) begin
                            score <= score + 50;
                            combo <= combo + 1;
                            hit_result[i] <= 1'b1;
                            hit_indicator[i] <= 1'b1;
                        end
                        else if(note_timer[i] < MISS_THRESHOLD) begin
                            score <= score + 20;
                            combo <= 4'd0;
                            hit_result[i] <= 1'b1;
                        end
                        
                        note_timer[i] <= 16'd0;
                    end
                    else if(note_timer[i] > MISS_THRESHOLD) begin
                        combo <= 4'd0;
                        note_timer[i] <= 16'd0;
                    end
                end
                else begin
                    note_timer[i] <= 16'd0;
                end
            end
        end
        else begin
            combo <= 4'd0;
            hit_indicator <= 4'b0;
        end
    end

endmodule
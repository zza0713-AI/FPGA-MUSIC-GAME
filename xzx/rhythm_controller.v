`timescale 1ns / 1ps

module rhythm_controller(
    input clk,
    input clk_audio,
    input rst_n,
    input game_start,
    input [2:0] difficulty,
    
    output reg game_active,
    output reg audio_playing,
    output reg [15:0] audio_addr,
    output reg note_valid,
    output reg [3:0] new_note,
    output reg beat_pulse
);

    // ============ 参数定义 ============
    parameter AUDIO_LENGTH = 176400;  // 44.1kHz × 4秒 = 176400采样点
    parameter BEATS_PER_SECOND = 120; // BPM=120 → 2拍/秒
    
    // ============ 节拍计数器 ============
    reg [31:0] audio_sample_counter;
    reg [31:0] beat_counter;
    reg [7:0] beat_in_measure;
    
    // ============ 音符生成逻辑 ============
    reg [15:0] note_timer;
    reg [15:0] note_interval;
    reg [3:0] note_pattern[0:15];
    reg [3:0] pattern_index;
    
    // ============ 难度配置 ============
    always @(*) begin
        case(difficulty)
            3'b000: begin  // 简单
                note_interval = 16'd4410; // 0.1秒间隔
                note_pattern[0] = 4'b0001;
                note_pattern[1] = 4'b0010;
                note_pattern[2] = 4'b0100;
                note_pattern[3] = 4'b1000;
            end
            3'b001: begin  // 普通
                note_interval = 16'd2205; // 0.05秒间隔
                note_pattern[0] = 4'b0001;
                note_pattern[1] = 4'b0010;
                note_pattern[2] = 4'b0100;
                note_pattern[3] = 4'b1000;
                note_pattern[4] = 4'b0011;
                note_pattern[5] = 4'b1100;
            end
            3'b010: begin  // 困难
                note_interval = 16'd1103; // 0.025秒间隔
                note_pattern[0] = 4'b0001;
                note_pattern[1] = 4'b0010;
                note_pattern[2] = 4'b0100;
                note_pattern[3] = 4'b1000;
                note_pattern[4] = 4'b0011;
                note_pattern[5] = 4'b1100;
                note_pattern[6] = 4'b0101;
                note_pattern[7] = 4'b1010;
                note_pattern[8] = 4'b0110;
                note_pattern[9] = 4'b1001;
            end
            default: begin  // 专家
                note_interval = 16'd551;  // 0.0125秒间隔
                for(integer i=0; i<16; i=i+1)
                    note_pattern[i] = i[3:0];
            end
        endcase
    end
    
    // ============ 游戏状态机 ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            game_active <= 1'b0;
            audio_playing <= 1'b0;
            audio_addr <= 16'd0;
            audio_sample_counter <= 32'd0;
            beat_counter <= 32'd0;
            beat_in_measure <= 8'd0;
            note_valid <= 1'b0;
            new_note <= 4'b0;
            note_timer <= 16'd0;
            pattern_index <= 4'd0;
        end
        else begin
            // 游戏开始控制
            if(game_start && !game_active) begin
                game_active <= 1'b1;
                audio_playing <= 1'b1;
            end
            
            if(game_active) begin
                // 音频播放控制
                if(audio_playing) begin
                    if(clk_audio) begin
                        audio_addr <= audio_addr + 1;
                        audio_sample_counter <= audio_sample_counter + 1;
                        
                        // 节拍检测
                        if(audio_sample_counter >= 32'd4410) begin
                            audio_sample_counter <= 32'd0;
                            beat_pulse <= 1'b1;
                            beat_counter <= beat_counter + 1;
                            beat_in_measure <= beat_in_measure + 1;
                            
                            if(beat_in_measure >= 8'd7) begin
                                beat_in_measure <= 8'd0;
                            end
                        end
                        else begin
                            beat_pulse <= 1'b0;
                        end
                    end
                    
                    // 检查音频是否结束
                    if(audio_addr >= AUDIO_LENGTH) begin
                        audio_playing <= 1'b0;
                        game_active <= 1'b0;
                    end
                end
                
                // 音符生成逻辑
                note_timer <= note_timer + 1;
                if(note_timer >= note_interval) begin
                    note_timer <= 16'd0;
                    note_valid <= 1'b1;
                    
                    new_note <= note_pattern[pattern_index];
                    pattern_index <= pattern_index + 1;
                    
                    if(pattern_index >= 4'd15) begin
                        pattern_index <= 4'd0;
                    end
                end
                else begin
                    note_valid <= 1'b0;
                end
            end
            else begin
                note_valid <= 1'b0;
                audio_playing <= 1'b0;
                beat_pulse <= 1'b0;
            end
        end
    end

endmodule
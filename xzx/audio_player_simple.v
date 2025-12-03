`timescale 1ns / 1ps

module audio_player_simple(
    input clk_audio,          // 音频时钟（44.1kHz）
    input rst_n,
    input game_active,
    input [15:0] audio_addr,  // 音频地址
    
    output reg [15:0] audio_data,
    output reg pwm_out        // PWM音频输出
);

    // ============ PWM音频生成 ============
    reg [15:0] pwm_counter;
    reg [15:0] pwm_threshold;
    
    always @(posedge clk_audio or negedge rst_n) begin
        if(!rst_n) begin
            audio_data <= 16'd0;
            pwm_counter <= 16'd0;
            pwm_threshold <= 16'd0;
            pwm_out <= 1'b0;
        end
        else if(game_active) begin
            // 从ROM读取音频数据（实际由audio_rom模块提供）
            // audio_data <= audio_rom[audio_addr];
            
            // PWM生成
            pwm_threshold <= {1'b0, audio_data[14:0]};
            
            if(pwm_counter < pwm_threshold) begin
                pwm_out <= 1'b1;
            end
            else begin
                pwm_out <= 1'b0;
            end
            
            pwm_counter <= pwm_counter + 1;
        end
        else begin
            pwm_out <= 1'b0;
        end
    end

endmodule
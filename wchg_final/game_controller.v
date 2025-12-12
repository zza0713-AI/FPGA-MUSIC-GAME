`timescale 1ns / 1ps

/**
 * Game Controller - State Machine
 * 管理游戏状态和状态转换
 */

module game_controller(
    input clk,
    input rst_n,
    input f_key_pause,                  // F5: 暂停/继续，按下按钮为低电平
    output reg game_state               // 0=运行, 1=暂停
);
    reg pause_pressed_reg;
    // ============ 状态转换 ============
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            game_state <= 1'b0;  // 复位到运行状态
            pause_pressed_reg <= 1'b0;
        end
        else begin
            pause_pressed_reg <= f_key_pause;
            if(pause_pressed_reg && !f_key_pause) begin  //按下输出低电平，当按下时触发
                game_state <= ~game_state;  // 切换暂停运行状态
            end
        end
    end

endmodule
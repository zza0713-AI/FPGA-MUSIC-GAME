`timescale 1ns / 1ps

/**
 * Block Manager - ROM Mode (Fixed)
 * 1. 统一使用单时钟域(clk)，clk_refresh改为使能信号
 * 2. 消除多驱动：所有寄存器只在单个always块中赋值
 * 3. chart_address移除组合逻辑赋值，完全时序化
 * 4. 优化状态机结构，符合"组合逻辑计算次态 + 时序逻辑更新现态"标准模式
 */

module block_manager_rom(
    input clk,
    input rst_n,
    input [31:0]clk_refresh_enable,     // 使能信号
    input game_state,                   // 0=运行, 1=暂停
    input [3:0] f_key_hit,              // F1-F4 按键信号
    input [3:0] sw_difficulty,          // (保留扩展用)
    input [1:0] chart_select,           // 选择曲目 (保留扩展用)
    
    output [255:0] frame_flat,
    output reg [6:0] score              // 分数输出，最高127分
);

    // ============ ROM接口 ============
    reg [15:0] chart_address;           // 当前ROM地址
    reg [3:0] chart_data;              // ROM数据输出
    reg [31:0] refresh_cnt;             // 下落计数器
    wire [3:0] video_data [3:0];        // 多曲目数据缓存
    
    // ROM实例化（实际项目应根据chart_select/sw_difficulty多路选择）
    chart_rom_easy chart_easy(.addr(chart_address),.data(video_data[0]));

    always @(*) begin
        case (chart_select)
            2'b00: chart_data = video_data[0];
            2'b01: chart_data = video_data[1];
            2'b10: chart_data = video_data[2];
            2'b11: chart_data = video_data[3];
            default: chart_data = 4'b0000;
        endcase
    end
    
    reg [15:0] frame [0:15];
    assign frame_flat = {frame[15], frame[14], frame[13], frame[12],
                        frame[11], frame[10], frame[9],  frame[8],
                        frame[7],  frame[6],  frame[5],  frame[4],
                        frame[3],  frame[2],  frame[1],  frame[0]};

    // ============ 状态机寄存器 ============
    integer i;                          // 循环变量
    reg [3:0] block_array [15:0];       // 4 列 x 16 行矩阵
    reg [3:0] block_array_next [15:0];  // 次态缓存
    reg [6:0] score_next;               // 次态缓存
    reg [1:0] miss_cnt;                 // 错过计数器（0-3次）,3次则游戏结束
    reg [1:0] miss_cnt_next;
    reg game_over;                      //游戏结束
    reg game_over_next;
    reg miss_detected;                  // 错过事件标志

    integer row, col;
    reg [3:0] hit_flags;  // 临时命中标志
            
    // ============ 组合逻辑：计算次态 ============
    // 功能：根据当前状态和输入，计算下一周期的block_array和score
    always @(*) begin
        // 默认保持当前值（pause状态或无需更新时）
        score_next = score;
        miss_cnt_next = miss_cnt;
        game_over_next = game_over;
        miss_detected = 1'b0;
        for(i = 0; i < 16; i = i + 1) begin
            block_array_next[i] = block_array[i];
        end
        
        // 复位
        if(!rst_n) begin
            score_next = 7'd0;
            miss_cnt_next = 2'd0;
            game_over_next = 1'b0;
            for(i = 0; i < 16; i = i + 1) begin
                block_array_next[i] = 4'b0;
            end
        end
        // 运行状态：处理下落、命中和加载新行
        else if(!game_state && !game_over) begin
            
            // 1. 检测F1-F4命中（仅最底行row=15）
            hit_flags = 4'b0;
            for(col = 0; col < 4; col = col + 1) begin
                if(f_key_hit[col] && block_array[15][col]) begin
                    hit_flags[col] = 1'b1;
                    score_next = score + 1;  // 命中加分
                end
            end

            // 2. 检测错过事件：底行有方块但未被击中
            for(col = 0; col < 4; col = col + 1) begin
                if(block_array[15][col] && !hit_flags[col]) begin
                    miss_detected = 1'b1;  // 只要有一个方块错过即触发
                end
            end
            
            // 3. 更新miss计数，达到3次则游戏结束
            if(miss_detected) begin
                miss_cnt_next = miss_cnt + 1;
                if(miss_cnt >= 2) begin  // 当前已是第2次，再错过则累计3次
                    game_over_next = 1'b1;  // 第三次错过，游戏结束
                end
            end

            // 4. 若游戏未结束，执行方块下落和加载新行
            if(!game_over_next) begin                   //判断次态，确保刚置位game_over时停止更新
                // 方块下落逻辑（从底到顶扫描）
                for(row = 15; row > 0; row = row - 1) begin: fall_loop
                    for(col = 0; col < 4; col = col + 1) begin: col_loop
                        // 最底行且命中：清除该块（消行效果）
                        if(hit_flags[col] && (row == 15)) begin
                            block_array_next[row][col] = 1'b0;
                        end
                        // 否则：方块下移一行
                        else begin
                            block_array_next[row][col] = block_array[row-1][col];
                        end
                    end
                end
                
                // 从ROM加载新行到顶部(row=0)
                for(col = 0; col < 4; col = col + 1) begin
                    block_array_next[0][col] = chart_data[col];
                end
            end
        end
        // pause状态：自动保持当前值，无需额外处理
    end

    // ============ 时序逻辑：统一更新现态 ============
    // 功能：在clk上升沿，当clk_refresh_en有效时，原子性更新所有寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 同步复位：所有状态清零
            score <= 7'd0;
            refresh_cnt <= 32'd0;
            chart_address <= 16'd0;
            miss_cnt <= 2'd0;
            game_over <= 1'b0;
            for(i = 0; i < 16; i = i + 1) begin
                block_array[i] <= 4'b0;
            end
        end else begin
            if(refresh_cnt >= clk_refresh_enable) begin
                refresh_cnt <= 32'd0;
            end else begin
                refresh_cnt <= refresh_cnt + 1;
            end

                //更新frame用于LED显示
                if(!game_over)begin  //在游戏没结束时刷新状态
                    // 仅在刷新使能有效时更新（控制下落速度）
                    if(refresh_cnt == clk_refresh_enable-1) begin
                    // 更新游戏状态
                    score <= score_next;
                    for (i = 0; i < 16; i = i + 1) begin
                        block_array[i] <= block_array_next[i];
                    end
                    miss_cnt <= miss_cnt_next;
                    game_over <= game_over_next;

                    // ROM地址循环递增（播放谱面）
                    if(chart_address < 16'd65535) begin
                        chart_address <= chart_address + 1;               //这里需要根据实际情况修改
                    end else begin
                        chart_address <= 16'd0;  // 循环播放
                    end

                    frame[0] <=  block_array[0];  //显示时候3列显示同一个音游通道
                    frame[1] <=  block_array[0];
                    frame[2] <=  block_array[0];
                    frame[3] <=  16'b0;           //每个音游通道中间间隔一个空列
                    frame[4] <=  block_array[1];
                    frame[5] <=  block_array[1];
                    frame[6] <=  block_array[1];
                    frame[7] <=  16'b0;
                    frame[8] <=  block_array[2];
                    frame[9] <=  block_array[2];
                    frame[10] <=  block_array[2];
                    frame[11] <=  16'b0;
                    frame[12] <=  block_array[3];
                    frame[13] <=  block_array[3];
                    frame[14] <=  block_array[3];
                    frame[15] <=  16'b0;
                end else begin
                    //游戏结束显示good game
                    frame[0]  = 16'b0111_0110_0111_0110; // g top + g bottom
                    frame[1]  = 16'b0101_0010_0101_0010;
                    frame[2]  = 16'b0111_1110_0111_1110;
                    frame[3]  = 16'b0000_0000_0000_0000; // spacer
                    frame[4]  = 16'b0011_1100_0111_1000; // o top + a bottom
                    frame[5]  = 16'b0010_0100_0100_1000;
                    frame[6]  = 16'b0011_1100_0111_1100;
                    frame[7]  = 16'b0000_0000_0000_0000; // spacer
                    frame[8]  = 16'b0000_0000_0111_1000; // o top + m bottom
                    frame[9]  = 16'b0011_1100_0100_0000;
                    frame[10] = 16'b0010_0100_0010_0000;
                    frame[11] = 16'b0011_1100_0100_0000; // spacer
                    frame[12] = 16'b0000_0000_0111_1000; // d top + e bottom
                    frame[13] = 16'b0000_1110_0000_0000;
                    frame[14] = 16'b0000_1010_0111_1100;
                    frame[15] = 16'b0111_1110_0101_0100; // spacer
                end
                
            end
        end
    end

endmodule
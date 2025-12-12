module block_manager_rom(
    input clk,
    input rst_n,
    input [31:0] clk_refresh_enable,    // 使能信号
    input game_state,                   // 0=运行, 1=暂停
    input [3:0] f_key_hit,              // F1-F4 按键信号
    input [3:0] sw_difficulty,          // (保留扩展用)
    input [1:0] chart_select,           // 选择曲目 (保留扩展用)
    
    output [255:0] frame_flat,
    output reg [6:0] score,             // 分数输出，最高127分
    output computer_valid,              //电脑外接设备输入有效
    output reg [7:0]computer_in         //电脑外接设备输入
);
    // ============ 电脑输入接口 ============
    reg [7:0]pre_computer_in;
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            pre_computer_in <= 8'b0;
        else
            pre_computer_in <= computer_in;
            //computer赋值       
            //为1代表这个时候命中，为0代表没有命中 
            computer_in[0] = !((f_key_hit[0] && block_array[15][0])||(f_key_hit[1] && block_array[15][1])||(f_key_hit[2] && block_array[15][2])||(f_key_hit[3] && block_array[15][3])); 
            computer_in[1] = rst_n;
            computer_in[3:2] = chart_select;
            computer_in[4] = game_state;
            computer_in[7:5] = 3'b111;       //保留高位全1
    end
    assign computer_valid = (pre_computer_in != computer_in) ? 1'b1 : 1'b0;

    // ============ ROM接口 ============
    reg [15:0] chart_address;           // 当前ROM地址
    reg [3:0] chart_data;               // ROM数据输出
    reg [31:0] refresh_cnt;             // 下落计数器
    wire [3:0] video_data [3:0];        // 多曲目数据缓存
    
    // ROM实例化（实际项目应根据chart_select/sw_difficulty多路选择）
    chunriyin chunriyin_rom(.address(chart_address), .clock(clk), .q(video_data[0]));
    see see_rom(.address(chart_address), .clock(clk), .q(video_data[1]));
    lemon lemon_rom(.address(chart_address), .clock(clk), .q(video_data[2]));
    qing qing_rom(.address(chart_address), .clock(clk), .q(video_data[3]));

    always @(*) begin
        if(!rst_n)begin
            chart_data = 4'b0000;
        end else begin
            case (chart_select)
                2'b00: chart_data = video_data[0];
                2'b01: chart_data = video_data[1];
                2'b10: chart_data = video_data[2];
                2'b11: chart_data = video_data[3];
                default: chart_data = 4'b0000;
            endcase
        end
    end
    
    reg [15:0] frame [0:15];
    assign frame_flat = {frame[15], frame[14], frame[13], frame[12],
                         frame[11], frame[10], frame[9],  frame[8],
                         frame[7],  frame[6], frame[5], frame[4],
                         frame[3], frame[2], frame[1], frame[0]};

    // ============ 状态机寄存器 ============
    integer i;                          // 循环变量
    reg [3:0] block_array [15:0];       // 4 列 x 16 行矩阵
    reg [3:0] block_array_next [15:0];  // 次态缓存
    reg [6:0] score_next;               // 次态缓存
    reg [1:0] miss_cnt;                 // 错过计数器（0-3次）,3次则游戏结束
    reg [1:0] miss_cnt_next;
    reg game_over;                      // 游戏结束
    reg game_over_next;
    reg miss_detected;                  // 错过事件标志

    integer row, col;
    reg [3:0] hit_flags;  // 临时命中标志
    
    // ============ 组合逻辑：计算次态 ============
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
            if(!game_over_next) begin
                // 方块下落逻辑（从上到下扫描）
                for(col = 0; col < 4; col = col + 1) begin: col_loop
                    // 从第二行开始，将上一行的方块向下移动
                    for(row = 15; row > 0; row = row - 1) begin: row_loop
                        block_array_next[row][col] = block_array[row-1][col];
                    end
                    
                    // 最底行：如果命中了就清除该块，否则将上一行的方块下移
                    if(hit_flags[col] && (block_array[15][col] != 4'b0)) begin
                        block_array_next[15][col] = 4'b0;  // 消除该块（消行效果）
                    end else begin
                        block_array_next[0][col] = chart_data[col];  // 从ROM加载新行
                    end
                end
            end
        end
    end

    // ============ 时序逻辑：统一更新现态 ============
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
                frame[i] <= 16'b0;
            end
        end else begin
            if(refresh_cnt >= clk_refresh_enable) begin
                refresh_cnt <= 32'd0;
            end else begin
                refresh_cnt <= refresh_cnt + 1;
            end

            // 更新frame用于LED显示
            if(!game_over) begin  // 在游戏没结束时刷新状态
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
                        chart_address <= chart_address + 1;  // 更新地址
                    end else begin
                        chart_address <= 16'd0;  // 循环播放
                    end

                    // 更新frame显示（多通道音符显示）
                    frame[0] <=  {block_array[ 0][0],
                                  block_array[ 1][0],
                                  block_array[ 2][0],
                                  block_array[ 3][0],
                                  block_array[ 4][0],
                                  block_array[ 5][0],
                                  block_array[ 6][0],
                                  block_array[ 7][0],
                                  block_array[ 8][0],
                                  block_array[ 9][0],
                                  block_array[10][0],
                                  block_array[11][0],
                                  block_array[12][0],
                                  block_array[13][0],
                                  block_array[14][0],
                                  block_array[15][0]};
                    frame[1] <=  {block_array[ 0][0],
                                  block_array[ 1][0],
                                  block_array[ 2][0],
                                  block_array[ 3][0],
                                  block_array[ 4][0],
                                  block_array[ 5][0],
                                  block_array[ 6][0],
                                  block_array[ 7][0],
                                  block_array[ 8][0],
                                  block_array[ 9][0],
                                  block_array[10][0],
                                  block_array[11][0],
                                  block_array[12][0],
                                  block_array[13][0],
                                  block_array[14][0],
                                  block_array[15][0]};                  
                    frame[ 2] <= {block_array[ 0][0],
                                  block_array[ 1][0],
                                  block_array[ 2][0],
                                  block_array[ 3][0],
                                  block_array[ 4][0],
                                  block_array[ 5][0],
                                  block_array[ 6][0],
                                  block_array[ 7][0],
                                  block_array[ 8][0],
                                  block_array[ 9][0],
                                  block_array[10][0],
                                  block_array[11][0],
                                  block_array[12][0],
                                  block_array[13][0],
                                  block_array[14][0],
                                  block_array[15][0]};               
                    frame[ 3] <= 16'b0000_0000_0000_0000;  // 空列间隔
                    frame[ 4] <= {block_array[ 0][1],
                                  block_array[ 1][1],
                                  block_array[ 2][1],
                                  block_array[ 3][1],
                                  block_array[ 4][1],
                                  block_array[ 5][1],
                                  block_array[ 6][1],
                                  block_array[ 7][1],
                                  block_array[ 8][1],
                                  block_array[ 9][1],
                                  block_array[10][1],
                                  block_array[11][1],
                                  block_array[12][1],
                                  block_array[13][1],
                                  block_array[14][1],
                                  block_array[15][1]};
                    frame[ 5] <= {block_array[ 0][1],
                                  block_array[ 1][1],
                                  block_array[ 2][1],
                                  block_array[ 3][1],
                                  block_array[ 4][1],
                                  block_array[ 5][1],
                                  block_array[ 6][1],
                                  block_array[ 7][1],
                                  block_array[ 8][1],
                                  block_array[ 9][1],
                                  block_array[10][1],
                                  block_array[11][1],
                                  block_array[12][1],
                                  block_array[13][1],
                                  block_array[14][1],
                                  block_array[15][1]};
                    frame[ 6] <= {block_array[ 0][1],
                                  block_array[ 1][1],
                                  block_array[ 2][1],
                                  block_array[ 3][1],
                                  block_array[ 4][1],
                                  block_array[ 5][1],
                                  block_array[ 6][1],
                                  block_array[ 7][1],
                                  block_array[ 8][1],
                                  block_array[ 9][1],
                                  block_array[10][1],
                                  block_array[11][1],
                                  block_array[12][1],
                                  block_array[13][1],
                                  block_array[14][1],
                                  block_array[15][1]};
                    frame[ 7] <=  16'b0;
                    frame[ 8] <= {block_array[ 0][2],
                                  block_array[ 1][2],
                                  block_array[ 2][2],
                                  block_array[ 3][2],
                                  block_array[ 4][2],
                                  block_array[ 5][2],
                                  block_array[ 6][2],
                                  block_array[ 7][2],
                                  block_array[ 8][2],
                                  block_array[ 9][2],
                                  block_array[10][2],
                                  block_array[11][2],
                                  block_array[12][2],
                                  block_array[13][2],
                                  block_array[14][2],
                                  block_array[15][2]};
                    frame[ 9] <= {block_array[ 0][2],
                                  block_array[ 1][2],
                                  block_array[ 2][2],
                                  block_array[ 3][2],
                                  block_array[ 4][2],
                                  block_array[ 5][2],
                                  block_array[ 6][2],
                                  block_array[ 7][2],
                                  block_array[ 8][2],
                                  block_array[ 9][2],
                                  block_array[10][2],
                                  block_array[11][2],
                                  block_array[12][2],
                                  block_array[13][2],
                                  block_array[14][2],
                                  block_array[15][2]};
                    frame[10] <= {block_array[ 0][2],
                                  block_array[ 1][2],
                                  block_array[ 2][2],
                                  block_array[ 3][2],
                                  block_array[ 4][2],
                                  block_array[ 5][2],
                                  block_array[ 6][2],
                                  block_array[ 7][2],
                                  block_array[ 8][2],
                                  block_array[ 9][2],
                                  block_array[10][2],
                                  block_array[11][2],
                                  block_array[12][2],
                                  block_array[13][2],
                                  block_array[14][2],
                                  block_array[15][2]};
                    frame[11] <= 16'b0;
                    frame[12] <= {block_array[ 0][3],
                                  block_array[ 1][3],
                                  block_array[ 2][3],
                                  block_array[ 3][3],
                                  block_array[ 4][3],
                                  block_array[ 5][3],
                                  block_array[ 6][3],
                                  block_array[ 7][3],
                                  block_array[ 8][3],
                                  block_array[ 9][3],
                                  block_array[10][3],
                                  block_array[11][3],
                                  block_array[12][3],
                                  block_array[13][3],
                                  block_array[14][3],
                                  block_array[15][3]}; 
                    frame[13] <= {block_array[ 0][3],
                                  block_array[ 1][3],
                                  block_array[ 2][3],
                                  block_array[ 3][3],
                                  block_array[ 4][3],
                                  block_array[ 5][3],
                                  block_array[ 6][3],
                                  block_array[ 7][3],
                                  block_array[ 8][3],
                                  block_array[ 9][3],
                                  block_array[10][3],
                                  block_array[11][3],
                                  block_array[12][3],
                                  block_array[13][3],
                                  block_array[14][3],
                                  block_array[15][3]}; 
                    frame[14] <= {block_array[ 0][3],
                                  block_array[ 1][3],
                                  block_array[ 2][3],
                                  block_array[ 3][3],
                                  block_array[ 4][3],
                                  block_array[ 5][3],
                                  block_array[ 6][3],
                                  block_array[ 7][3],
                                  block_array[ 8][3],
                                  block_array[ 9][3],
                                  block_array[10][3],
                                  block_array[11][3],
                                  block_array[12][3],
                                  block_array[13][3],
                                  block_array[14][3],
                                  block_array[15][3]}; 
                    frame[15] <= 16'b0;
                end
            end else begin
                // 游戏结束显示“Good Game”
                frame[0]  <= 16'b0111_0110_0111_0110; // g top + g bottom
                frame[1]  <= 16'b0101_0010_0101_0010;
                frame[2]  <= 16'b0111_1110_0111_1110;
                frame[3]  <= 16'b0000_0000_0000_0000; // spacer
                frame[4]  <= 16'b0011_1100_0111_1000; // o top + a bottom
                frame[5]  <= 16'b0010_0100_0100_1000;
                frame[6]  <= 16'b0011_1100_0111_1100;
                frame[7]  <= 16'b0000_0000_0000_0000; // spacer
                frame[8]  <= 16'b0000_0000_0111_1000; // o top + m bottom
                frame[9]  <= 16'b0011_1100_0100_0000;
                frame[10] <= 16'b0010_0100_0010_0000;
                frame[11] <= 16'b0011_1100_0100_0000; // spacer
                frame[12] <= 16'b0000_0000_0111_1000; // d top + e bottom
                frame[13] <= 16'b0000_1110_0000_0000;
                frame[14] <= 16'b0000_1010_0111_1100;
                frame[15] <= 16'b0111_1110_0101_0100; // spacer
            end
        end
    end

endmodule
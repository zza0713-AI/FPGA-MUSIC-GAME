//score分数显示
module ScanDisplayDriver #(
    parameter integer CLOCK_FREQ = 25_000_000,  // 默认 25MHz
    parameter integer REFRESH_HZ = 1000         // 每个数码管刷新频率（Hz）
)(
    input              clk_sys,    // 系统时钟
    input              resetn,     // 低有效复位
    input      [6:0]   score ,     // 得分,最高3位127
    output reg [7:0]   seg,        // 段选输出 {a,b,c,d,e,f,g,dp} 高有效
    output     [3:0]   sel         // 位选输出（低有效）
);

    // 参数 / 计数器，用于刷新和 1s 滚动定时
    localparam REFRESH_COUNTER_WIDTH = 16; // 决定扫描速率
    reg [REFRESH_COUNTER_WIDTH-1:0] refresh_cnt;

    //定义0-9的数码管显示参数
    localparam [7:0] SEG_0 = 8'hFC; //0
    localparam [7:0] SEG_1 = 8'h60; //1
    localparam [7:0] SEG_2 = 8'hDA; //2
    localparam [7:0] SEG_3 = 8'hF2; //3
    localparam [7:0] SEG_4 = 8'h66; //4
    localparam [7:0] SEG_5 = 8'hB6; //5
    localparam [7:0] SEG_6 = 8'hBE; //6
    localparam [7:0] SEG_7 = 8'hE0; //7
    localparam [7:0] SEG_8 = 8'hFE; //8
    localparam [7:0] SEG_9 = 8'hF6; //9
    localparam [7:0] SEG_SPACE = 8'h00; //空格

    // 使用 refresh_cnt 的高 2 bit 做index索引（固定0..3循环）
    wire [1:0] index = refresh_cnt[REFRESH_COUNTER_WIDTH-1 -: 2];
    reg [31:0] display_data;  //最高分数127，4位数码管显示即可

    // 当前扫描的数码管索引（0~3）
    reg [1:0] digit_idx;

    // 刷新计数器与索引更新
    always @(posedge clk_sys or negedge resetn) begin
        if (!resetn) begin
            refresh_cnt <= 0;
            digit_idx   <= 0;
            display_data <= 32'b0;
        end else begin
            // refresh_cnt始终+1，提供稳定的index 0--7循环
            refresh_cnt <= refresh_cnt+1;
            //选通数码管根据index切换
            digit_idx <= index; 

            //根据score给diaplay_data赋值
            display_data[31:24] <= SEG_SPACE; //用不到最高位，直接不显示，全灭
            if(score >= 100)begin //对百位显示，大于100显示1，否则显示0
                display_data[23:16] <= SEG_1;
            end else begin
                display_data[23:16] <= SEG_0; 
            end
            case ((score/10)%10) //十位
                4'd0: display_data[15:8] <= SEG_0;
                4'd1: display_data[15:8] <= SEG_1;
                4'd2: display_data[15:8] <= SEG_2;
                4'd3: display_data[15:8] <= SEG_3;
                4'd4: display_data[15:8] <= SEG_4;
                4'd5: display_data[15:8] <= SEG_5;
                4'd6: display_data[15:8] <= SEG_6;
                4'd7: display_data[15:8] <= SEG_7;
                4'd8: display_data[15:8] <= SEG_8;
                4'd9: display_data[15:8] <= SEG_9;
                default: display_data[15:8] <= SEG_SPACE; //否则输出空格，方便检测
            endcase
            case (score%10) //个位
                4'd0: display_data[7:0] <= SEG_0;
                4'd1: display_data[7:0] <= SEG_1;
                4'd2: display_data[7:0] <= SEG_2;
                4'd3: display_data[7:0] <= SEG_3;
                4'd4: display_data[7:0] <= SEG_4;
                4'd5: display_data[7:0] <= SEG_5;
                4'd6: display_data[7:0] <= SEG_6;
                4'd7: display_data[7:0] <= SEG_7;
                4'd8: display_data[7:0] <= SEG_8;
                4'd9: display_data[7:0] <= SEG_9;
                default: display_data[7:0] <= SEG_SPACE; //否则输出空格，方便检测
            endcase
        end
    end
    // 输出驱动逻辑
    always @(*) begin
        seg = display_data[digit_idx*8+7 -:8]; // 输出当前选中的段码
    end

    // sel 低有效：只有当前位为 0，其余为 1
    assign sel = ~(4'b0001 << digit_idx);

endmodule
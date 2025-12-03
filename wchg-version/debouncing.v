//==============================================================
// Module: debouncing
// Function: 按键去抖动模块
// Author: (your name)
//--------------------------------------------------------------
// Description:
//   对输入的机械按键信号进行去抖处理。
//   当检测到按键按下（低电平）时，启动计数器。
//   若按键持续稳定低电平超过 delayT 个时钟周期，
//   输出 key 变为低；
//   当按键松开（高电平）时，立即输出高电平。
//--------------------------------------------------------------
// Parameters:
//   bitwidth : 计数器位宽
//   delayT   : 去抖延迟时间（单位：时钟周期）
//==============================================================
module debouncing #(
    parameter bitwidth = 20,
    parameter delayT   = 250_000   // e.g. 对于 50MHz 时钟约 5ms 延迟
)(
    input  wire clk_sys,  // 系统时钟
    input  wire key_b,    // 原始按键输入（低有效）
    output reg  key,       // 去抖动后的按键信号（低有效）, 信号持续时间约为按下时间
    output key_pulse  // 去抖动后的按键信号（低有效），信号仅持续一个周期
);

    //==========================================================
    // 内部寄存器
    //==========================================================
    reg [bitwidth-1:0] counter = delayT;  // 去抖计数器
    reg prev_key;//记录原来的key值，用于生成脉冲key_pulse

    //==========================================================
    // 计数逻辑：
    //   当检测到按键按下（key_b=0 且 key=1）时，启动计数。
    //   按键保持低电平时计数器递增；
    //   计数达到 delayT 时认为按键稳定。
    //==========================================================
    always @(negedge clk_sys) begin
        if ((counter == delayT) && (key_b == 1'b0) && (key == 1'b1)) begin
            counter <= 0;  // 检测到按下瞬间，启动计数
        end
        else if (counter < delayT) begin
            counter <= counter + 1'b1;  // 继续计数
        end
        // 当 counter == delayT 时保持不变
    end

    //==========================================================
    // 输出逻辑：
    //   - 若按键持续低电平 delayT 个周期后，输出 key 拉低；
    //   - 若按键释放（key_b=1），立即输出高电平。
    //==========================================================
    always @(negedge clk_sys) begin
        if ((counter == delayT) && (key_b == 1'b0)) begin
            key <= 1'b0;  // 稳定按下
        end
        else if (key_b == 1'b1) begin
            key <= 1'b1;  // 立即恢复为高电平（释放）
        end
        prev_key<=key;
    end

    //仅当key下降沿，key_pulse为0
    assign key_pulse=~(prev_key&(~key));

endmodule




//==============================================================
// Module: debouncing (三段式状态机版)
// Function: 按键去抖动模块
// Author: (your name)
//--------------------------------------------------------------
// Description:
//   使用有限状态机(FSM)实现按键去抖。
//   当检测到按键按下（低电平）时启动计数，
//   若稳定时间超过 delayT，则认为按下有效；
//   松开时立即恢复。
//--------------------------------------------------------------
// Parameters:
//   bitwidth : 计数器位宽
//   delayT   : 去抖延迟时间（单位：时钟周期）
//==============================================================
module debouncing_fsm #(
    parameter bitwidth = 20,
    parameter delayT   = 250_000   // e.g. 对于 50MHz 时钟约 5ms 延迟
)(
    input  wire clk_sys,   // 系统时钟
    input  wire resetn,     // 异步复位（低有效）
    input  wire key_b,     // 原始按键信号（低有效）
    output reg  key,       // 去抖后的按键信号（低有效，保持按下时间）
    output key_pulse  // 仅一个时钟周期的脉冲（低有效）
);

    //==========================================================
    // 1. 状态定义
    //==========================================================
    localparam    IDLE     = 2'b00;  // 等待按下
    localparam    COUNTING = 2'b01;  // 去抖计数中
    localparam    PRESSED  = 2'b10;  // 按下稳定

    reg [1:0] current_state, next_state;
    reg [bitwidth-1:0] counter, next_counter;

    //==========================================================
    // 2. 状态寄存器
    //==========================================================
    always @(posedge clk_sys or negedge resetn) begin
        if (!resetn) begin
            current_state <= IDLE;
            counter <=delayT;
        end else begin
            current_state <= next_state;
            counter <=next_counter;
        end
    end

    //==========================================================
    // 3. 状态转移逻辑
    //==========================================================


    always @(*) begin
        next_state = current_state; // 默认保持
		next_counter = counter;
        case (current_state)
            IDLE: begin
                next_counter=delayT;
                if (key_b == 1'b0)        // 检测到按下
                    next_state = COUNTING;
            end
            COUNTING: begin
                if (counter >0) begin
                     // 消抖计数中
                    next_counter =counter -1;
                    next_state =COUNTING;
                end else if (key_b == 1'b1) begin   // 中途松开
                    next_counter = delayT;
                    next_state = IDLE;
                end
                else begin //counter==0,计数结束，按键稳定
                    next_state = PRESSED;
                    next_counter =0;
                end
            end
            PRESSED: begin
                next_counter =0;
                if (key_b == 1'b1)        // 松开
                    next_state = IDLE;
            end
        endcase
    end

    //==========================================================
    // 4. 状态输出与计数逻辑
    //==========================================================
    reg prev_key;

    always @(posedge clk_sys or negedge resetn) begin
        if (!resetn) begin
            key       <= 1'b1;
            prev_key  <= 1'b1;
        end else begin
            case (current_state)
                IDLE: begin
                    key  <= 1'b1; // 未按下
                end
                COUNTING: begin
                    key <= 1'b0; // 稳定按下
                end
                PRESSED: begin
                    key <= 1'b0; // 稳定按下
                end
            endcase

            // 生成单周期脉冲：下降沿有效（低电平）
            prev_key  <= key;
        end
    end
        //仅当key下降沿，key_pulse为0
    assign key_pulse=~(prev_key&(~key));

endmodule

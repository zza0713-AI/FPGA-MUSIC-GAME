`timescale 1ns / 1ps

module music_game_top(
    input clk,                          // 50MHz 系统时钟
    input rst_n_key,                    // 复位（低电平有效）
    
    // 按键输入
    input [4:0] f_keys,                 // F1~F5 按键, F1~F4 用于击打，F5 用于暂停/继续
    input [5:0] sw_switches,            // SW1~SW6 开关，1-4用来控制难度，5-6选择曲目
    
    // LED 矩阵 (16x16)
    output [15:0] col_data,              // 行扫描信号
    output [3:0]  col_sel,               // 列驱动信号
    
    // 数码管输出 (8位)
    output [3:0] sel,                   // 数码管位选
    output [7:0] seg,               // 数码管段驱动 (a-g)

    //电脑uart接口
    output computer_out
);
    // computer_out = f_keys[3];
    // 内部信号
    wire clk_refresh;                   // 方块下落时钟
    wire clk_scan;                      // 矩阵扫描时钟
    wire clk_seg;                       // 数码管扫描时钟
    wire [31:0] clk_refresh_enable;     // 方块下落时钟使能信号
    wire pause;                         // 暂停键状态
    wire [255:0] frame_flat;            // 展平的显示帧数据
    wire rst_n;
    wire [3:0] f_keys_debounced;        // 消抖后的按键状态
    
    wire [31:0] score;                  // 分数
    wire game_state;                    // 游戏状态 (0=运行, 1=暂停)
    wire [7:0]computer_in;              // 电脑外接设备输入
    wire computer_valid;               // 电脑外接设备输入有效信号
    
    wire [3:0] block_array [15:0];      // 4 列 x 16 行矩阵
    
    // ============ debouncing ============
    debouncing debouncing_obj1(.clk_sys(clk), .key_b(rst_n_key), .key(rst_n), .key_pulse());
    debouncing debouncing_obj2(.clk_sys(clk), .key_b(f_keys[4]), .key(pause), .key_pulse());  // F5 暂停键
    debouncing debouncing_obj3(.clk_sys(clk), .key_b(f_keys[3]), .key(f_keys_debounced[3]), .key_pulse());
    debouncing debouncing_obj4(.clk_sys(clk), .key_b(f_keys[2]), .key(f_keys_debounced[2]), .key_pulse());
    debouncing debouncing_obj5(.clk_sys(clk), .key_b(f_keys[1]), .key(f_keys_debounced[1]), .key_pulse());
    debouncing debouncing_obj6(.clk_sys(clk), .key_b(f_keys[0]), .key(f_keys_debounced[0]), .key_pulse());
    //

    // ============ clock_divider ============
    clock_divider clk_div_inst(
        .clk(clk),
        .rst_n(rst_n),
        .difficulty(sw_switches[3:0]),
        .refresh_max(clk_refresh_enable[31:0]),
        .clk_scan(clk_scan)
    );
    
    // ============ Game Controller ============
    game_controller game_ctrl_inst(
        .clk(clk),
        .rst_n(rst_n),
        .f_key_pause(pause),         // F5: 暂停/继续
        .game_state(game_state)
    );
    
    // ============ Block Manager (ROM mode) ============
    block_manager_rom block_mgr_inst(
        .clk(clk),
        . rst_n(rst_n),
        .clk_refresh_enable(clk_refresh_enable[31:0]),
        .game_state(game_state),
        .f_key_hit(~f_keys_debounced[3:0]),         // F1~F4
        .sw_difficulty(sw_switches[3:0]),
        .chart_select(sw_switches[5:4]),
        .frame_flat(frame_flat),
        .score(score),
        .computer_valid(computer_valid),
        .computer_in(computer_in[7:0])
    );
    
    // ============ LED Matrix Driver ============
    led_matrix_driver led_drv_inst(
        .clk(clk_scan),
        .rst(~rst_n),
        .frame(frame_flat),
        .col_data(col_data),
        .col_sel(col_sel)
    );
    
    // ============ 7-Segment Display Driver ============
    ScanDisplayDriver sScanDisplayDriver_inst(
        .clk_sys(clk),
        .resetn(rst_n),
        .score(score),
        .seg(seg),
        .sel(sel)
    );

    // ============ UART Transmitter ============
    uart_tx #(
        .CLK_FRE(50),               // MHz
        .BAUD_RATE(115200)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data_valid(computer_valid),       //1为数据有效
        .tx_data(computer_in[7:0]),
        .tx_data_ready(),
        .tx_pin(computer_out)
    );

endmodule

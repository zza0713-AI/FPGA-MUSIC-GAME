`timescale 1ns / 1ps

module music_game_top_rhythm(
    input clk_50m,                     // 50MHz系统时钟
    input rst_n,                       // 复位按钮
    
    // 游戏控制输入
    input [3:0] f_keys,               // F1-F4按键
    input [15:0] sw,                  // 拨码开关
    input start_btn,                  // 开始按钮（SW16）
    
    // 显示输出
    output [15:0] led_row,            // LED矩阵行
    output [15:0] led_col,            // LED矩阵列
    output [7:0] seg_select,          // 数码管位选
    output [6:0] seg_data,            // 数码管段选
    
    // 音频输出
    output audio_pwm,                  // PWM音频输出
    output [3:0] led_hit,             // 击中指示灯
    output [7:0] led_status           // 状态LED
);

    // ============ 内部信号 ============
    wire clk_audio;                    // 音频时钟
    wire clk_refresh;                  // 游戏刷新时钟
    wire clk_scan;                     // LED扫描时钟
    wire clk_seg;                      // 数码管扫描时钟
    
    wire [31:0] score;                 // 得分
    wire [3:0] combo_count;           // 连击数
    wire [7:0] accuracy;               // 准确率
    
    wire game_active;                  // 游戏进行中
    wire audio_playing;                // 音频播放中
    
    wire [3:0] note_column [15:0];    // 16行×4列音符矩阵
    wire [3:0] new_note;              // 新出现的音符
    wire note_valid;                  // 新音符有效
    
    wire [15:0] audio_data;
    wire [15:0] audio_addr;
    
    wire [3:0] hit_indicator;
    wire beat_pulse;
    
    // ============ 按键消抖 ============
    wire [3:0] f_keys_debounced;
    
    key_detector_sync key_det_inst(
        .clk(clk_50m),
        .rst_n(rst_n),
        .f_keys_in(f_keys),
        .f_keys_out(f_keys_debounced)
    );
    
    // ============ 时钟生成 ============
    clock_divider_rhythm clk_gen(
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .difficulty(sw[2:0]),
        .clk_audio(clk_audio),
        .clk_refresh(clk_refresh),
        .clk_scan(clk_scan),
        .clk_seg(clk_seg)
    );
    
    // ============ 同步控制器 ============
    sync_controller sync_ctrl_inst(
        .clk(clk_50m),
        .rst_n(rst_n),
        .game_start(start_btn),
        .difficulty(sw[2:0]),
        .game_active(game_active),
        .beat_pulse(beat_pulse),
        .current_beat(new_note),
        .audio_addr(audio_addr),
        .beat_addr()
    );
    
    // ============ 节奏控制器 ============
    rhythm_controller rhythm_ctrl_inst(
        .clk(clk_50m),
        .clk_audio(clk_audio),
        .rst_n(rst_n),
        .game_start(start_btn),
        .difficulty(sw[2:0]),
        .game_active(game_active),
        .audio_playing(audio_playing),
        .audio_addr(audio_addr),
        .note_valid(note_valid),
        .new_note(new_note),
        .beat_pulse(beat_pulse)
    );
    
    // ============ 音符生成器 ============
    note_generator note_gen_inst(
        .clk(clk_refresh),
        .rst_n(rst_n),
        .game_active(game_active),
        .difficulty(sw[3:0]),
        .note_valid(note_valid),
        .new_note(new_note),
        .note_columns(note_column)
    );
    
    // ============ 游戏逻辑 ============
    game_logic logic_inst(
        .clk(clk_50m),
        .rst_n(rst_n),
        .game_active(game_active),
        .f_keys(f_keys_debounced),
        .bottom_row(note_column[15]),
        .hit_accuracy(sw[7]),
        .score(score),
        .combo(combo_count),
        .accuracy(accuracy),
        .hit_indicator(hit_indicator)
    );
    
    // ============ 音频播放器 ============
    audio_player_simple audio_inst(
        .clk_audio(clk_audio),
        .rst_n(rst_n),
        .game_active(game_active),
        .audio_addr(audio_addr),
        .audio_data(audio_data),
        .pwm_out(audio_pwm)
    );
    
    // ============ 音频ROM ============
    audio_rom audio_mem(
        .clk(clk_audio),
        .addr(audio_addr),
        .data(audio_data)
    );
    
    // ============ LED矩阵驱动 ============
    led_matrix_rhythm led_matrix_inst(
        .clk(clk_50m),
        .clk_scan(clk_scan),
        .rst_n(rst_n),
        .note_columns(note_column),
        .hit_leds(hit_indicator),
        .led_row(led_row),
        .led_col(led_col)
    );
    
    // ============ 数码管显示 ============
    seg_display_rhythm seg_display_inst(
        .clk(clk_seg),
        .rst_n(rst_n),
        .score(score),
        .combo(combo_count),
        .accuracy(accuracy),
        .game_mode(sw[3:0]),
        .seg_select(seg_select),
        .seg_data(seg_data)
    );
    
    // ============ 状态LED显示 ============
    assign led_hit = hit_indicator;
    
    reg [7:0] status_reg;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n) begin
            status_reg <= 8'b0000_0000;
        end
        else begin
            if(game_active) begin
                status_reg <= {4'b0000, combo_count};
            end
            else begin
                status_reg <= 8'b1010_1010;
            end
        end
    end
    
    assign led_status = status_reg;

endmodule
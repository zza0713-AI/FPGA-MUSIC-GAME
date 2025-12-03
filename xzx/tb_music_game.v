`timescale 1ns / 1ps

module tb_music_game;

    reg clk_50m;
    reg rst_n;
    reg [3:0] f_keys;
    reg [15:0] sw;
    reg start_btn;
    
    wire [15:0] led_row;
    wire [15:0] led_col;
    wire [7:0] seg_select;
    wire [6:0] seg_data;
    wire audio_pwm;
    wire [3:0] led_hit;
    wire [7:0] led_state;
    
    music_game_top_rhythm uut(
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .f_keys(f_keys),
        .sw(sw),
        .start_btn(start_btn),
        .led_row(led_row),
        .led_col(led_col),
        .seg_select(seg_select),
        .seg_data(seg_data),
        .audio_pwm(audio_pwm),
        .led_hit(led_hit),
        .led_status(led_state)
    );
    
    // 时钟生成
    initial begin
        clk_50m = 0;
        forever #10 clk_50m = ~clk_50m;
    end
    
    // 测试序列
    initial begin
        // 初始化
        rst_n = 0;
        f_keys = 4'b0;
        sw = 16'b0;
        start_btn = 0;
        #100;
        
        // 复位释放
        rst_n = 1;
        #100;
        
        // 设置游戏参数
        sw[2:0] = 3'b001;  // 普通难度
        sw[7] = 1;         // 开启精度判定
        #100;
        
        // 开始游戏
        start_btn = 1;
        #100;
        start_btn = 0;
        
        // 等待游戏开始
        #1000000;
        
        // 模拟按键打击
        repeat(20) begin
            #2000000;  // 等待2ms
            f_keys = 4'b0001;  // 按下F1
            #10000;
            f_keys = 4'b0;     // 释放
            #1000000;
            
            f_keys = 4'b0010;  // 按下F2
            #10000;
            f_keys = 4'b0;
            #1000000;
        end
        
        // 观察完整游戏流程
        #10000000;
        
        $finish;
    end
    
    // 波形保存
    initial begin
        $dumpfile("music_game.vcd");
        $dumpvars(0, tb_music_game);
    end
    
    // 监控输出
    always @(posedge clk_50m) begin
        if(uut.game_active) begin
            $display("Time: %0t, Score: %0d, Combo: %0d", $time, uut.score, uut.combo_count);
        end
    end

endmodule
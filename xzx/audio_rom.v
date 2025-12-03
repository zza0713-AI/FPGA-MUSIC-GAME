`timescale 1ns / 1ps

module audio_rom(
    input clk,
    input [15:0] addr,
    output reg [15:0] data
);

    parameter DEPTH = 176400;  // 4秒 × 44100Hz
    
    reg [15:0] rom [0:DEPTH-1];
    
    initial begin
        $readmemh("game_audio.mif", rom);
        $display("音频ROM加载完成，深度: %0d", DEPTH);
    end
    
    always @(posedge clk) begin
        if(addr < DEPTH)
            data <= rom[addr];
        else
            data <= 16'd0;
    end

endmodule
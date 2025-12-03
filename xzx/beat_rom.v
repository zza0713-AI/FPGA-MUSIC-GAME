`timescale 1ns / 1ps

module beat_rom(
    input clk,
    input [15:0] addr,
    output reg [3:0] data
);

    parameter DEPTH = 600;  // 60秒 ÷ 0.1s
    
    reg [3:0] rom [0:DEPTH-1];
    
    initial begin
        $readmemb("game_beats.mif", rom);
        $display("节拍ROM加载完成，深度: %0d", DEPTH);
    end
    
    always @(posedge clk) begin
        if(addr < DEPTH)
            data <= rom[addr];
        else
            data <= 4'b0;
    end

endmodule
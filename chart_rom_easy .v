`timescale 1ns / 1ps

/**
 * Easy Mode Chart ROM
 * Auto-generated from example_easy.mid
 * BPM: 120. 00
 * Total steps: 1200
 * Duration: 60. 00s
 */

module chart_rom_easy (
    input [15:0] addr,
    output reg [3:0] data
);

    reg [3:0] rom [0:1199];

    initial begin
        // 地址 0000 - 0007
        rom[0] = 4'b0000;
        rom[1] = 4'b0000;
        rom[

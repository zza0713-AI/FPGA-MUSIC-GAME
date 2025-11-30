// chart_rom_easy.v
// Chart ROM Implementation for Easy Mode in FPGA Music Game
// Example music patterns for easy mode

module chart_rom_easy (
    input [7:0] address,
    output reg [15:0] data
);

// Easy Mode Music Patterns
reg [15:0] rom [0:255];

// Initialize the ROM with example patterns
initial begin
    // Example pattern 1
    rom[0] = 16'b0000000000000001; // Note ON at time 0
    rom[1] = 16'b0000000000000010; // Note OFF at time 1
    rom[2] = 16'b0000000000000001; // Note ON at time 2
    rom[3] = 16'b0000000000000010; // Note OFF at time 3
    
    // Example pattern 2
    rom[4] = 16'b0000000000000100; // Note ON at time 4
    rom[5] = 16'b0000000000000110; // Note OFF at time 5
    rom[6] = 16'b0000000000000100; // Note ON at time 6
    rom[7] = 16'b0000000000000110; // Note OFF at time 7
    
    // Continue defining more patterns...
end

// Access ROM content
always @(address) begin
    data = rom[address];
end

endmodule
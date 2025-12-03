module led_matrix_driver(
    input  wire clk,
    input  wire rst,
    input  wire [255:0] frame,
    output reg  [15:0] col_data,
    output reg  [3:0]  col_sel
);
    reg [3:0] col_idx;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            col_idx <= 0;
            col_data <= 16'h0000;
            col_sel <= 4'd0;
        end else begin
                col_idx <= col_idx + 1;
                col_sel <= col_idx;
                col_data <= frame[col_idx*16+:16];
        end
    end
endmodule

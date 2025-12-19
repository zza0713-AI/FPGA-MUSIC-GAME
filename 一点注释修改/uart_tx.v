module uart_tx
#(
	parameter CLK_FRE = 50,      //时钟频率(Mhz)
	parameter BAUD_RATE = 115200 //串口波特率
)
(
	input                        clk,              //时钟输入
	input                        rst_n,            //异步复位输入，低电平有效
	input[7:0]                   tx_data,          //发送数据
	input                        tx_data_valid,    //发送数据有效标志
	output reg                   tx_data_ready,    //发送准备就绪
	output                       tx_pin            //串口数据输出
);
//计算波特率对应的时钟周期
localparam                       CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
//状态机编码
localparam                       S_IDLE       = 1;//空闲状态
localparam                       S_START      = 2;//起始位
localparam                       S_SEND_BYTE  = 3;//数据位
localparam                       S_STOP       = 4;//停止位
reg[2:0]                         state;
reg[2:0]                         next_state;
reg[15:0]                        cycle_cnt; //波特率计数器
reg[2:0]                         bit_cnt;//比特计数器
reg[7:0]                         tx_data_latch; //发送数据锁存
reg                              tx_reg; //串口数据输出寄存器
assign tx_pin = tx_reg;
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		state <= S_IDLE;
	else
		state <= next_state; //次态赋给现态
end

always@(*)
begin
	case(state)
		S_IDLE:
			if(tx_data_valid == 1'b1)
				next_state <= S_START;
			else
				next_state <= S_IDLE;
		S_START:
			if(cycle_cnt == CYCLE - 1)
				next_state <= S_SEND_BYTE;
			else
				next_state <= S_START;
		S_SEND_BYTE:
			if(cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)
				next_state <= S_STOP;
			else
				next_state <= S_SEND_BYTE;
		S_STOP:
			if(cycle_cnt == CYCLE - 1)
				next_state <= S_IDLE;
			else
				next_state <= S_STOP;
		default:
			next_state <= S_IDLE;
	endcase
end
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_ready <= 1'b0;
		end
	else if(state == S_IDLE)
		if(tx_data_valid == 1'b1)
			tx_data_ready <= 1'b0;
		else
			tx_data_ready <= 1'b1;
	else if(state == S_STOP && cycle_cnt == CYCLE - 1)
			tx_data_ready <= 1'b1;
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_latch <= 8'd0;
		end
	else if(state == S_IDLE && tx_data_valid == 1'b1)
			tx_data_latch <= tx_data;
		
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			bit_cnt <= 3'd0;
		end
	else if(state == S_SEND_BYTE)
		if(cycle_cnt == CYCLE - 1)
			bit_cnt <= bit_cnt + 3'd1;
		else
			bit_cnt <= bit_cnt;
	else
		bit_cnt <= 3'd0;
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		cycle_cnt <= 16'd0;
	else if((state == S_SEND_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
		cycle_cnt <= 16'd0;
	else
		cycle_cnt <= cycle_cnt + 16'd1;	
end
//输出逻辑
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		tx_reg <= 1'b1;
	else
		case(state)
			S_IDLE,S_STOP:
				tx_reg <= 1'b1;  
			S_START:
				tx_reg <= 1'b0;  
			S_SEND_BYTE:
				tx_reg <= tx_data_latch[bit_cnt];  
			default:
				tx_reg <= 1'b1;
		endcase
end

endmodule 
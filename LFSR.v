module LFSR(
input clk,
input reset,
input load_condition, 
input [15:0] seed,
output [15:0] lfsr_out
);

localparam	tap1 = 0;
localparam	tap2 = 2;
localparam	tap3 = 3;
localparam	tap4 = 5;

wire feedback;


Shift_Register #(.W(16)) lf_shift(
.clk(clk),
.reset(reset),
.load_condition(load_condition),
.shift_condition(1'b1), // Shift right	
.serial_in(feedback),
.load_value(seed),
.register_out(lfsr_out)
);

assign feedback = lfsr_out[tap1] ^ lfsr_out[tap2] ^ lfsr_out[tap3] ^ lfsr_out[tap4];

endmodule
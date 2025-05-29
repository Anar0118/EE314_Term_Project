module MUXx#(parameter W=4 // default 4-bit data
)
(
	input          select,
	input  [W-1:0] mux_input_0,
	input  [W-1:0] mux_input_1,
	output reg [W-1:0] mux_output
);

always@(*) begin
	case(select)
	1'b0: mux_output = mux_input_0;
	1'b1: mux_output = mux_input_1;
	default: mux_output = {W{1'b0}};
	endcase
end

endmodule
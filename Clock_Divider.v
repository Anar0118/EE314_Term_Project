module Clock_Divider #(parameter DIVISOR = 2)
(
input clk,
input reset,
output reg clk_out
);

reg [31:0] count;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		count <= 0;
		clk_out <= 0;
	end 
	else begin
		if (count >= (DIVISOR/2 - 1)) begin
			clk_out <= ~clk_out;
			count <= 0;
		end 
		else
			count <= count + 1;
   end
end

endmodule
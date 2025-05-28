module Small_Game(
input clk,
input left,
input right,
input attack,
input reset,
output reg move_flag,
output reg directional_attack_flag,
output reg attack_flag,
output reg [2:0] state
);

reg[2:0] CS,NS;
localparam[2:0] S_IDLE = 0;
localparam S_Left = 1;
localparam S_Right = 2;
localparam S_Attack_start = 3;
localparam S_Attack_active = 4;

always@(*) begin: Next_State_Module
	case(CS)
		S_IDLE: begin
			if (attack)
				NS = S_Attack_start;
			else if (left)
				NS = S_Left;
			else if (right)
				NS = S_Right;
			else
				NS = S_IDLE;
		end
		
		S_Left: begin
			if (attack)
				NS = S_Attack_start;
			else if (left)
				NS = S_Left;
			else if (right)
				NS = S_Right;
			else
				NS = S_IDLE;
		end
		
		S_Right:begin
			if (attack)
				NS = S_Attack_start;
			else if (left)
				NS = S_Left;
			else if (right)
				NS = S_Right;
			else
				NS = S_IDLE;
		end
		
		S_Attack_start: NS = S_Attack_active;
		S_Attack_active: NS = S_IDLE;
		default: NS = S_IDLE;
	endcase
end

always@(posedge clk) begin: Current_State
	if (reset)
		CS <= S_IDLE;
	else
		CS <= NS;
end


always@(*) begin: Output
	move_flag = (CS == S_Left || CS == S_Right);
	directional_attack_flag = (attack && (CS == S_Left || CS == S_Right));
	attack_flag = (CS == S_Attack_start || CS == S_Attack_active);
	state = CS;
end

endmodule
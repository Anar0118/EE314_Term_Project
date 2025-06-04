module Game(
input clk,
input switch,
output reg led0,
output reg led1,
output reg led2,
output reg led3,
output reg led4,
output reg [3:0] counter
);

reg[1:0] CS,NS;
reg[2:0] lives = 4;

localparam[1:0] S_Counting = 0;
localparam S_stop = 1;
localparam S_win = 2;
localparam S_lose = 3;

initial begin
counter = 0;
end

always@(*) begin: Next_State_Module
	case(CS)
		S_Counting: begin
			if (switch)
				NS = S_stop;
			else
				NS = S_Counting;
		end
		
		S_stop: begin
			if (counter == 9)
				NS = S_win;
			else
				NS = S_lose;
		end
		
		S_lose:begin
			if ( (lives > 0) && (switch == 0) )
				NS = S_Counting;
			else
				NS = S_lose;
		end
		
		S_win: NS = S_win;
		default: NS = S_Counting;
	endcase
end


always@(posedge clk) begin: Current_State
	CS <= NS;
	
	if (CS == S_Counting) begin
		if (counter == 15)
			counter <= 0;
		else
			counter <= counter + 1;
	end

	if ((CS == S_stop) && ~(counter == 9) && (lives > 0))
		lives <= lives - 1;
end


always@(*) begin: Output
	led0 = 0;
	led1 = 0;
	led2 = 0;
	led3 = 0;
	led4 = 0;
	
	if (lives == 4) begin
		led0 = 1;
		led1 = 1;
		led2 = 1;
		led3 = 1;
		led4 = 0;
	end
	else if (lives == 3) begin
		led0 = 1;
		led1 = 1;
		led2 = 1;
		led3 = 0;
		led4 = 0;
	end
	else if (lives == 2) begin
		led0 = 1;
		led1 = 1;
		led2 = 0;
		led3 = 0;
		led4 = 0;
	end
	else if (lives == 1) begin
		led0 = 1;
		led1 = 0;
		led2 = 0;
		led3 = 0;
		led4 = 0;
	end
	else if (lives == 0) begin
		led0 = 0;
		led1 = 0;
		led2 = 0;
		led3 = 0;
		led4 = 1;
	end

end


endmodule
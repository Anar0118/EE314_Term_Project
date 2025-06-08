module Hit_Detector(
	input       clk,
	input       reset,
	input [3:0] state_1,
	input [3:0] state_2,
	input [9:0] p1_x,
	input [9:0] p2_x,
	input 		attacking1,
	input 		dir_attacking1,
	input 		attacking2,
	input 		dir_attacking2,
	output reg hit1_flag,  // player1 hitted player2
	output reg hit2_flag,  // player1 hitted player2
	output reg stun1_flag, // player1 stunned
	output reg stun2_flag, // player2 stunned
	//output reg [5:0] leds,
	output reg led1,
	output reg led2,
	output reg led3,
	output reg led4,
	output reg led5,
	output reg led6
);

localparam [3:0] S_MOVE_BWD   = 4'd2;
localparam [3:0] S_ATTACK_ACT = 4'd6;

reg [1:0] lives1 = 2'd3;
reg [1:0] lives2 = 2'd3;


reg [9:0] HIT_WIDTH1;
reg [9:0] HIT_WIDTH2;

always@(*) begin
	HIT_WIDTH1  = 10'd0;
	HIT_WIDTH2  = 10'd0;
	
	if (dir_attacking1) begin
		HIT_WIDTH1  = 10'd20;
	end
	else if (attacking1) begin
		HIT_WIDTH1  = 10'd32;
	end
	
	if (dir_attacking2) begin
		HIT_WIDTH2  = 10'd20;
	end
	else if (attacking2) begin
		HIT_WIDTH2  = 10'd32;
	end
	
	
end



//reg attack1;
//reg attack2;

wire attack1  = (state_1 == S_ATTACK_ACT);
wire attack2  = (state_2 == S_ATTACK_ACT);

// Block detection (moving backward)
//wire p1_blocking = (state_1 == S_MOVE_BWD);
//wire p2_blocking = (state_2 == S_MOVE_BWD);




always@(posedge clk or posedge reset) begin
	if (reset) begin
		hit1_flag  <= 1'd0;
		hit2_flag  <= 1'd0;
		stun1_flag <= 1'd0;
		stun2_flag <= 1'd0;
		lives1 <= 2'd3;
		lives2 <= 2'd3;
		//leds <= 6'b111_111; // All LEDs on at reset
		led1 <= 1'd1;
		led2 <= 1'd1;
		led3 <= 1'd1;
		led4 <= 1'd1;
		led5 <= 1'd1;
		led6 <= 1'd1;
	end
	
	else begin
	
		//attack1 <= (state_1 == S_ATTACK_ACT);
		//attack2 <= (state_2 == S_ATTACK_ACT);
		
		// Clear hit flags when attacks are finished
		if (~attack1) hit1_flag <= 1'd0;
		if (~attack2) hit2_flag <= 1'd0;
	
		if (attack1 && (~attack2) && (~hit1_flag)) begin
			if (p1_x + 10'd64 + HIT_WIDTH1 > p2_x) begin
				hit1_flag <= 1'd1;
				stun2_flag <= 1'd1;
				lives2 <= lives2 - 2'd1;
			end
		end
		
		if ((~attack1) && attack2 && (~hit2_flag)) begin
			if (p2_x - HIT_WIDTH2 - 10'd64 < p1_x) begin
				hit2_flag <= 1'd1;
				stun1_flag <= 1'd1;
				lives1 <= lives1 - 1'd1;
			end
		end
		
		if (attack1 && attack2 && (~hit1_flag) && (~hit2_flag)) begin
			if (p1_x + 10'd64 + HIT_WIDTH1 > p2_x) begin
				hit1_flag <= 1'd1;
				stun2_flag <= 1'd1;
				lives2 <= lives2 - 2'd1;
			end
			
			if (p2_x - HIT_WIDTH2 - 10'd64 < p1_x) begin
				hit2_flag <= 1'd1;
				stun1_flag <= 1'd1;
				lives1 <= lives1 - 1'd1;
			end
			/*
			hit1_flag  <= 1'd1;
			hit2_flag  <= 1'd1;
			stun1_flag <= 1'd1;
			stun2_flag <= 1'd1;
			lives1 <= lives1 - 1'd1;
			lives2 <= lives2 - 1'd1;
			*/
		end
		
		
		// Update LEDs based on lives
		case(lives1)
		2'd3: 
		begin
			led1 <= 1'd1;
			led2 <= 1'd1;
			led3 <= 1'd1;
		end
		
		2'd2:
		begin
			led1 <= 1'd1;
			led2 <= 1'd1;
			led3 <= 1'd0;
		end
		
		2'd1:
		begin
			led1 <= 1'd1;
			led2 <= 1'd0;
			led3 <= 1'd0;
		end
		2'd0:
		begin
			led1 <= 1'd0;
			led2 <= 1'd0;
			led3 <= 1'd0;
		end
		
		default:
		begin
			led1 <= 1'd1;
			led2 <= 1'd1;
			led3 <= 1'd1;
		end
		endcase
		
		case(lives2)
		2'd3: 
		begin
			led4 <= 1'd1;
			led5 <= 1'd1;
			led6 <= 1'd1;
		end
		
		2'd2:
		begin
			led4 <= 1'd1;
			led5 <= 1'd1;
			led6 <= 1'd0;
		end
		
		2'd1:
		begin
			led4 <= 1'd1;
			led5 <= 1'd0;
			led6 <= 1'd0;
		end
		2'd0:
		begin
			led4 <= 1'd0;
			led5 <= 1'd0;
			led6 <= 1'd0;
		end
		
		default:
		begin
			led4 <= 1'd1;
			led5 <= 1'd1;
			led6 <= 1'd1;
		end
		endcase
	end


end

endmodule
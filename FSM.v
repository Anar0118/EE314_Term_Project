// ===================================================================
// Module: FSM
//   - Runs at 60 Hz frame_tick
//   - States: IDLE, MOVE_FWD (+3 px), MOVE_BWD (−2 px)
//   - Inputs: btn_left, btn_right
//   - Outputs: x_pos (10-bit), state (for debug/animation)
// ===================================================================
module FSM (
  input            clk,         // 60 Hz “game” clock
  input            reset,       // async reset, active high
  input            btn_left,    // move left?
  input            btn_right,   // move right?
  input				 btn_attack,
  input            player,      // 0-player1  1-player2
  input      [9:0] x_pos_opponent,
  output reg [9:0] x_pos,       // top‐left X of sprite
  output reg [2:0] state,       // current state (for debugging/anim)
  output reg		 attacking,
  output reg       dir_attacking,
  output reg [4:0] attack_frame
);

// state encoding
localparam [2:0] S_IDLE     = 3'd0;
localparam [2:0] S_MOVE_FWD = 3'd1;
localparam [2:0] S_MOVE_BWD = 3'd2;
localparam [2:0] S_ATTACK   = 3'd3;
localparam [2:0] S_DIR_ATTACK = 3'd4;
localparam [2:0] S_ATTACK_SU= 3'd5;
localparam [2:0] S_ATTACK_ACT= 3'd6;
localparam [2:0] S_ATTACK_REC= 3'd7; 
 // (you’ll add more like ATTACK, HITSTUN, etc.)

reg [2:0] ATTACK_STARTUP = 0;
reg [1:0] ATTACK_ACTIVE = 0;
reg [3:0] ATTACK_RECOVERY = 0;
 
// attack timing parameters (from Table 1 in Appendix A)
always@(*) begin
	ATTACK_STARTUP  = 0;
   ATTACK_ACTIVE   = 0;
   ATTACK_RECOVERY = 0;
	
	if (attacking) begin
		ATTACK_STARTUP  = 4;
		ATTACK_ACTIVE   = 1;
		ATTACK_RECOVERY = 15;
	end
	else if (dir_attacking) begin
		ATTACK_STARTUP  = 3;
		ATTACK_ACTIVE   = 2;
		ATTACK_RECOVERY = 14;
	end
end

 
// horizontal bounds
localparam [9:0] MIN_X = 10'd0;
localparam [9:0] MIN_X1 = 10'd640 - 10'd64;


// how many pixels per frame
localparam [1:0] FWD_STEP = 2'd3;
localparam [1:0] BWD_STEP = 2'd2;

// next‐state / next‐pos signals
reg [2:0]  nxt_state;
reg [9:0]  nxt_x;
reg        nxt_attacking;
reg        nxt_dir_attacking;
reg [4:0]  intertnal_attack_frame = 5'd0;

// combinational next‐state logic
always@(*) begin
	// default:
	nxt_state = state;
	nxt_x = x_pos;
	nxt_attacking = attacking;
	nxt_dir_attacking = dir_attacking;

	case (state)
	S_IDLE: begin
		if (btn_attack) begin
			nxt_state = S_ATTACK;
			nxt_attacking = 1;
			nxt_dir_attacking = 0;
		end
			
		else if (btn_right) nxt_state = S_MOVE_FWD;
		else if (btn_left ) nxt_state = S_MOVE_BWD;
		else nxt_state = S_IDLE;
	end

	S_MOVE_FWD: begin
		// move right
		case(player)
			1'd0: begin
				nxt_x = x_pos + FWD_STEP;
				if (nxt_x > x_pos_opponent - 64) nxt_x = x_pos_opponent - 64;
			end
			
			1'd1: begin
				nxt_x = x_pos - FWD_STEP;
				if (nxt_x < x_pos_opponent + 64) nxt_x = x_pos_opponent + 64;
			end
			default: nxt_x = x_pos;
		endcase
		
		if (btn_attack) begin
			nxt_state = S_DIR_ATTACK;
			nxt_attacking = 0;
			nxt_dir_attacking = 1;
		end
		// if key still held, stay moving, else go back to idle
		else if (!btn_right) nxt_state = S_IDLE;
	end

	S_MOVE_BWD: begin
		// move left
		case(player)
			1'd0: begin
				if (x_pos > BWD_STEP) nxt_x = x_pos - BWD_STEP;
				else nxt_x = MIN_X;
			end
			
			1'd1: begin
				if (x_pos < 640 - 64 - BWD_STEP) nxt_x = x_pos + BWD_STEP;
				else nxt_x = MIN_X1;
			end
			default: nxt_x = x_pos;
		endcase
		
		
		if (btn_attack) begin
        nxt_state = S_DIR_ATTACK;
		  nxt_dir_attacking = 1;
        nxt_attacking = 0;
      end
		
		// if key still held, stay moving, else go back to idle
		if (!btn_left) nxt_state = S_IDLE;
	end
	
	S_ATTACK: nxt_state = S_ATTACK_SU;
	
	S_DIR_ATTACK: nxt_state = S_ATTACK_SU;
	
	S_ATTACK_SU: begin
		if (intertnal_attack_frame == ATTACK_STARTUP) nxt_state = S_ATTACK_ACT;
		else nxt_state = S_ATTACK_SU;
	end
	
	S_ATTACK_ACT: begin
		if (intertnal_attack_frame == ATTACK_ACTIVE) nxt_state = S_ATTACK_REC;
		else nxt_state = S_ATTACK_ACT;
	end
	
	S_ATTACK_REC: begin
		if (intertnal_attack_frame == ATTACK_RECOVERY) begin
			nxt_state = S_IDLE;
			nxt_attacking = 0;
			nxt_dir_attacking = 0;
		end
		else nxt_state = S_ATTACK_REC;
			
	end

	default: nxt_state = S_IDLE;
 endcase
end

// sequential state & position update
always @(posedge clk or posedge reset) begin
		
	if (reset) begin
		state <= S_IDLE;
		attacking <= 0;
		dir_attacking <= 0;
		intertnal_attack_frame <= 0;
		attack_frame <= 0;

		// Proper starting positions for each player
		if (player == 1'd0) begin
			// Player 1 starts at left (10px from edge)
			x_pos <= 10'd10;
		end
		else begin
			// Player 2 starts at right (10px from edge - sprite width)
			x_pos <= 10'd640 - 10'd64 - 10'd10;
		end
	end 
	else begin
		state <= nxt_state;
		x_pos <= nxt_x;
		attacking <= nxt_attacking;
		dir_attacking <= nxt_dir_attacking;
		
		case(state)
		S_ATTACK_SU: begin
			if (intertnal_attack_frame != ATTACK_STARTUP) intertnal_attack_frame <= intertnal_attack_frame + 5'd1;
			else intertnal_attack_frame <= 0;
			attack_frame <= intertnal_attack_frame;
		end
		
		S_ATTACK_ACT: begin
			if (intertnal_attack_frame != ATTACK_ACTIVE) intertnal_attack_frame <= intertnal_attack_frame + 5'd1;
			else intertnal_attack_frame <= 0;
			attack_frame <= intertnal_attack_frame;
		end
		
		S_ATTACK_REC: begin
			if (intertnal_attack_frame != ATTACK_RECOVERY) intertnal_attack_frame <= intertnal_attack_frame + 5'd1;
			else intertnal_attack_frame <= 0;
			attack_frame <= intertnal_attack_frame;
		end
		default: begin 
			intertnal_attack_frame <= 0;
			attack_frame <= intertnal_attack_frame;
		end
		endcase
	end
end

endmodule

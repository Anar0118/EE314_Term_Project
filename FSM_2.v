
// ===================================================================
// Module: FSM
//   - Runs at 60 Hz frame_tick
//   - States: IDLE, MOVE_FWD (+3 px), MOVE_BWD (−2 px)
//   - Inputs: btn_left, btn_right
//   - Outputs: x_pos (10-bit), state (for debug/animation)
// ===================================================================
module FSM_2 (
  input            clk,         // 60 Hz “game” clock
  input            reset,       // async reset, active high
  input            btn_left,    // move left?
  input            btn_right,   // move right?
  input				 btn_attack,
  input      [9:0] x_pos_opponent,
  input            play_active,
  output reg [9:0] x_pos,       // top‐left X of sprite
  output reg [3:0] state,       // current state (for debugging/anim)
  output reg		 attacking,
  output reg       dir_attacking,
  output reg [4:0] attack_frame
);

// state encoding
localparam [3:0] S_IDLE       = 4'd0;
localparam [3:0] S_MOVE_FWD   = 4'd1;
localparam [3:0] S_MOVE_BWD   = 4'd2;
localparam [3:0] S_ATTACK     = 4'd3;
localparam [3:0] S_DIR_ATTACK = 4'd4;
localparam [3:0] S_ATTACK_SU  = 4'd5;
localparam [3:0] S_ATTACK_ACT = 4'd6;
localparam [3:0] S_ATTACK_REC = 4'd7;
//localparam [3:0] S_HITSTUN    = 4'd8;
//localparam [3:0] S_BLOCKSTUN  = 4'd9;
// (you’ll add more like ATTACK, HITSTUN, etc.)

// attack timing parameters (from Table 1 in Appendix A)
localparam [2:0] ATTACK_STARTUP = 3;  // startup frames
localparam [1:0] ATTACK_ACTIVE  = 2;  // active frames
localparam [3:0] ATTACK_RECOVERY= 14; // recovery frames
 
// horizontal bounds
localparam [9:0] MIN_X1 = 10'd640 - 10'd64;

// how many pixels per frame
localparam [1:0] FWD_STEP = 2'd3;
localparam [1:0] BWD_STEP = 2'd2;

// next‐state / next‐pos signals
reg [3:0]  nxt_state;
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
		if (~play_active) nxt_state = S_IDLE;
		else begin
			if (btn_attack) begin
				nxt_state = S_ATTACK;
				nxt_attacking = 1;
				nxt_dir_attacking = 0;
			end
				
			else if (btn_right) nxt_state = S_MOVE_FWD;
			else if (btn_left ) nxt_state = S_MOVE_BWD;
			else nxt_state = S_IDLE;
		end
	end

	S_MOVE_FWD: begin
		// move left (forward)
		nxt_x = x_pos - FWD_STEP;
		if (nxt_x < x_pos_opponent + 10'd64) nxt_x = x_pos_opponent + 10'd64;
		
		if (btn_attack) begin
			nxt_state = S_DIR_ATTACK;
			nxt_attacking = 0;
			nxt_dir_attacking = 1;
		end
		
		// if key still held, stay moving, else go back to idle
		else if (!btn_right) nxt_state = S_IDLE;
	end

	S_MOVE_BWD: begin
		// move right (backward)
		if (x_pos < 640 - 64 - BWD_STEP) nxt_x = x_pos + BWD_STEP;
		else nxt_x = MIN_X1;
		
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
		x_pos <= 10'd640 - 10'd64 - 10'd10;
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

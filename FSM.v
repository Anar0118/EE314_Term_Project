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
  output reg [9:0] x_pos,       // top‐left X of sprite
  output reg [2:0] state,       // current state (for debugging/anim)
  output reg		 attacking,
  output reg [3:0] attack_frame
);

// state encoding
localparam S_IDLE     = 3'd0;
localparam S_MOVE_FWD = 3'd1;
localparam S_MOVE_BWD = 3'd2;
localparam S_ATTACK   = 3'd3;
localparam S_ATTACK_SU= 3'd4;
localparam S_ATTACK_ACT= 3'd5;
localparam S_ATTACK_REC= 3'd6; 
 // (you’ll add more like ATTACK, HITSTUN, etc.)

// attack timing parameters (from Table 1 in Appendix A)
localparam ATTACK_STARTUP = 5;  // startup frames
localparam ATTACK_ACTIVE  = 2;  // active frames
localparam ATTACK_RECOVERY= 16; // recovery frames
localparam ATTACK_TOTAL   = ATTACK_STARTUP + ATTACK_ACTIVE + ATTACK_RECOVERY; 
 
 
// horizontal bounds
localparam MIN_X = 0;
localparam MAX_X = 640 - 64;  // 64-pixel wide sprite

// how many pixels per frame
localparam FWD_STEP = 3;
localparam BWD_STEP = 2;

// next‐state / next‐pos signals
reg [2:0]  nxt_state;
reg [9:0]  nxt_x;
reg        nxt_attacking;
reg [3:0]  nxt_attack_frame;

// combinational next‐state logic
always@(*) begin
	// default:
	nxt_state = state;
	nxt_x = x_pos;
	nxt_attacking = attacking;
   nxt_attack_frame = attack_frame;

	case (state)
	S_IDLE: begin
		if (btn_attack) begin
			nxt_state = S_ATTACK;
			nxt_attack_frame = 0;
			nxt_attacking = 1;
		end
			
		else if (btn_right) nxt_state = S_MOVE_FWD;
		else if (btn_left ) nxt_state = S_MOVE_BWD;
		else nxt_state = S_IDLE;
	end

	S_MOVE_FWD: begin
		// move right
		nxt_x = x_pos + FWD_STEP;
		if (nxt_x > MAX_X) nxt_x = MAX_X;
		
		if (btn_attack) begin
			nxt_state = S_ATTACK;
			nxt_attack_frame = 0;
			nxt_attacking = 1;
		end
		
		// if key still held, stay moving, else go back to idle
		else if (!btn_right) nxt_state = S_IDLE;
	end

	S_MOVE_BWD: begin
		// move left
		if (x_pos > BWD_STEP) nxt_x = x_pos - BWD_STEP;
		else nxt_x = MIN_X;
		
		if (btn_attack) begin
        nxt_state = S_ATTACK;
        nxt_attack_frame = 0;
        nxt_attacking = 1;
      end
		
		// if key still held, stay moving, else go back to idle
		if (!btn_left) nxt_state = S_IDLE;
	end
	
	S_ATTACK: begin
		// increment attack frame counter
		//nxt_attack_frame = attack_frame + 1;
			
      // check if attack animation is complete
      //if (attack_frame >= ATTACK_TOTAL-1) begin
		
		nxt_state = S_ATTACK_SU;
		//nxt_attacking = 0;
		//end
   end
	S_ATTACK_SU: nxt_state = S_ATTACK_ACT;
	S_ATTACK_ACT: nxt_state = S_ATTACK_REC;
	S_ATTACK_REC: begin
		nxt_state = S_IDLE;
		nxt_attacking = 0;
	end

	default: nxt_state = S_IDLE;
 endcase
end

// sequential state & position update
always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= S_IDLE;
		x_pos <= MIN_X + 10;   // start 10 px in from left
		attacking <= 0;
		attack_frame <= 0;
	end 
	else begin
		state <= nxt_state;
		x_pos <= nxt_x;
		attacking <= nxt_attacking;
		attack_frame <= nxt_attack_frame;
	end
end

endmodule

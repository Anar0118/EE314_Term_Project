// ===================================================================
// Module: character_renderer
// Draws a solid‐color rectangle of size 64×240 at (x_pos,y_pos).
// ===================================================================
module character_renderer (
	input        video_on,     // from vga_background
	input  [9:0] hcnt, vcnt,   // pixel counters from vga_sync
	input  [9:0] x_pos,        // sprite top‐left X
	input  [9:0] y_pos,        // sprite top‐left Y
	input 		 attacking,
	input	       dir_attacking,
	input  [2:0] state,
	input        switch,
	input        player_num,
	output       sprite_on,    // high when inside the rectangle
	output [3:0] r, g, b       // 4-bit RGB for the sprite
);
// Character dimensions
localparam WIDTH = 64;
localparam HEIGHT = 240;
localparam BORDER_WIDTH = 2; // 2-pixel wide border


reg [7:0] HIT_WIDTH;
reg [7:0] HIT_HEIGHT_TOP;
reg [7:0] HIT_HEIGHT_BOTTOM;

always@(*) begin
	HIT_WIDTH  = 8'd0;
   HIT_HEIGHT_TOP   = 8'd0;
	HIT_HEIGHT_BOTTOM   = 8'd0;
	
	if (dir_attacking) begin
		HIT_WIDTH  = 8'd20;
		HIT_HEIGHT_TOP   = 8'd100;
		HIT_HEIGHT_BOTTOM   = 8'd140;
	end
	else if (attacking) begin
		HIT_WIDTH  = 8'd32;
		HIT_HEIGHT_TOP   = 8'd80;
		HIT_HEIGHT_BOTTOM   = 8'd160;
	end
end


// within the 64×240 box -- in hurtbox?
wire in_x = (hcnt >= x_pos) && (hcnt < x_pos + WIDTH);
wire in_y = (vcnt >= y_pos) && (vcnt < y_pos + HEIGHT);
wire in_hurtbox = in_x && in_y;

// attack hitbox dimensions (extends forward during active frames)
wire in_hitbox_x = player_num ? (hcnt <= x_pos) && (hcnt > x_pos - HIT_WIDTH):
										  (hcnt >= x_pos + WIDTH) && (hcnt < x_pos + WIDTH + HIT_WIDTH); // 32px hitbox extension(x)
wire in_hitbox_y = (vcnt >= y_pos + HIT_HEIGHT_TOP) && (vcnt < y_pos + HIT_HEIGHT_BOTTOM);     // 80px hitbox extension(y) centered vertically
wire in_hitbox = in_hitbox_x && in_hitbox_y;


// Proper hurtbox outline (constrained to character area)
/*
wire hurtbox_outline = (
  // Left border (full height)
  ((hcnt >= x_pos) && (hcnt < x_pos + BORDER_WIDTH) && 
	(vcnt >= y_pos) && (vcnt < y_pos + HEIGHT)) ||
  
  // Right border (full height)
  ((hcnt >= x_pos + WIDTH - BORDER_WIDTH) && (hcnt < x_pos + WIDTH) && 
	(vcnt >= y_pos) && (vcnt < y_pos + HEIGHT)) ||
  
  // Top border (full width, excluding left/right borders)
  ((vcnt >= y_pos) && (vcnt < y_pos + BORDER_WIDTH) && 
	(hcnt >= x_pos + BORDER_WIDTH) && (hcnt < x_pos + WIDTH - BORDER_WIDTH)) ||
  
  // Bottom border (full width, excluding left/right borders)
  ((vcnt >= y_pos + HEIGHT - BORDER_WIDTH) && (vcnt < y_pos + HEIGHT) && 
	(hcnt >= x_pos + BORDER_WIDTH) && (hcnt < x_pos + WIDTH - BORDER_WIDTH))
);
*/


// determine if we're in active attack frames (from Table 1)
wire attack_active = (attacking || dir_attacking);

// Stick figure parameters (relative to hurtbox)
localparam HEAD_RADIUS = 20;
localparam BODY_LENGTH = 60;
localparam ARM_LENGTH_IDLE = 40;
localparam LEG_LENGTH_IDLE = 60;
// ATTACK POSE (when attacking)
localparam ARM_LENGTH_ATTACK = 50;
localparam LEG_LENGTH_ATTACK = 50;

// Stick figure coordinates (relative to character position)
wire [9:0] rel_x = hcnt - x_pos;
wire [9:0] rel_y = vcnt - y_pos;

// Head (circle)
wire [9:0] HEAD_CENTER_X = WIDTH/2;
wire [9:0] HEAD_CENTER_Y = 40;
wire [19:0] head_dist_sq = (rel_x-HEAD_CENTER_X)*(rel_x-HEAD_CENTER_X) + 
									(rel_y-HEAD_CENTER_Y)*(rel_y-HEAD_CENTER_Y);
wire head_on = (head_dist_sq < (HEAD_RADIUS*HEAD_RADIUS));

// Body (vertical line)
wire body_on = (rel_x >= HEAD_CENTER_X-2) && (rel_x <= HEAD_CENTER_X+2) &&
				   (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS) && 
				   (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH);
					
// Arms (angled lines)
wire left_arm_idle = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+20) &&
					    (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+20+ARM_LENGTH_IDLE) &&
					    (rel_x >= HEAD_CENTER_X - (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+20))/2) &&
					    (rel_x <= HEAD_CENTER_X - (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+20))/2 + 4);

wire right_arm_idle = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+20) &&
					     (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+20+ARM_LENGTH_IDLE) &&
					     (rel_x >= HEAD_CENTER_X + (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+20))/2 - 4) &&
					     (rel_x <= HEAD_CENTER_X + (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+20))/2);

// Legs (angled lines)
wire left_leg_idle = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH) &&
					    (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH_IDLE) &&
					    (rel_x >= HEAD_CENTER_X - (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH))/3) &&
					    (rel_x <= HEAD_CENTER_X - (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH))/3 + 4);

wire right_leg_idle = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH) &&
					     (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH_IDLE) &&
					     (rel_x >= HEAD_CENTER_X + (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH))/3 - 4) &&
					     (rel_x <= HEAD_CENTER_X + (rel_y-(HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH))/3);

						  
// Attack arms (one arm extended forward)
wire left_arm_attack = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+10) &&
						     (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+10+ARM_LENGTH_ATTACK) &&
						     (rel_x >= HEAD_CENTER_X - 10) &&
						     (rel_x <= HEAD_CENTER_X - 10 + 4) &&
						     (rel_y < HEAD_CENTER_Y+HEAD_RADIUS+10+ARM_LENGTH_ATTACK/2 || 
							   rel_x < HEAD_CENTER_X);

wire right_arm_attack = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+30) &&
							   (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+30+ARM_LENGTH_ATTACK/2) &&
							   (rel_x >= HEAD_CENTER_X + WIDTH/4) &&
							  (rel_x <= HEAD_CENTER_X + WIDTH/4 + 4);

// Attack legs (wider stance)
wire left_leg_attack = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH) &&
						     (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH_ATTACK) &&
						     (rel_x >= HEAD_CENTER_X - 15) &&
						     (rel_x <= HEAD_CENTER_X - 15 + 4);

wire right_leg_attack = (rel_y >= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH) &&
							   (rel_y <= HEAD_CENTER_Y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH_ATTACK) &&
							   (rel_x >= HEAD_CENTER_X + 15 - 4) &&
							   (rel_x <= HEAD_CENTER_X + 15);						  

// Select pose based on attack state
wire left_arm_on = attacking ? left_arm_attack : left_arm_idle;
wire right_arm_on = attacking ? right_arm_attack : right_arm_idle;
wire left_leg_on = attacking ? left_leg_attack : left_leg_idle;
wire right_leg_on = attacking ? right_leg_attack : right_leg_idle;							
						  
						  
// Combined stick figure
wire stick_figure_on = in_hurtbox && (head_on || body_on || left_arm_on || right_arm_on || left_leg_on || right_leg_on);


// Final sprite detection (hurtbox outline, stick figure, or active hitbox)
assign sprite_on = video_on && ((switch && in_hurtbox) || stick_figure_on || (attack_active && in_hitbox));
			  
// sprite is either body or active hitbox
//assign sprite_on = video_on && ( (in_hurtbox) || 
//										 (attack_active && in_hitbox_x && in_hitbox_y) );
//assign sprite_on = video_on && in_x && in_y;


  
reg [3:0] hit_r, hit_g, hit_b;
always @* begin
	case (state)
	4'd5: begin    // state == 4 → green
	hit_r = 4'h0; hit_g = 4'hF; hit_b = 4'h0;
	end
	4'd6: begin    // state == 5 → blue
		hit_r = 4'h0; hit_g = 4'h0; hit_b = 4'hF;
	end
	4'd7: begin    // state == 6 → red
		hit_r = 4'hF; hit_g = 4'h0; hit_b = 4'h0;
	end
	default: begin // default hitbox color (black)
		hit_r = 4'h0; hit_g = 4'h0; hit_b = 4'h0;
	end
	endcase
end


// Output colors
assign r = sprite_on ? ((attack_active && in_hitbox) ? hit_r : 
						     ((switch && in_hurtbox) ? 4'hF :       // red outline
						     ((stick_figure_on && player_num) ? 4'h0 : 
							  ((stick_figure_on && ~player_num) ? 4'h0: 4'h0)))) : 4'h0; // Black stick figure

assign g = sprite_on ? ((attack_active && in_hitbox) ? hit_g :
							  ((switch && in_hurtbox) ? 4'h0 : 
						     ((stick_figure_on && player_num) ? 4'h0 : 
							  ((stick_figure_on && ~player_num) ? 4'h0: 4'h0)))) : 4'h0;

assign b = sprite_on ? ((attack_active && in_hitbox) ? hit_b : 
						     ((switch && in_hurtbox) ? 4'h0 : 
						     ((stick_figure_on && player_num) ? 4'h0 : 
							  ((stick_figure_on && ~player_num) ? 4'hF: 4'h0)))) : 4'h0;
/*
assign r = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_r : CHAR_R) : 4'h0;
assign g = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_g : CHAR_G) : 4'h0;
assign b = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_b : CHAR_B) : 4'h0;
*/

//assign r = sprite_on ? CHAR_R : 4'h0;
//assign g = sprite_on ? CHAR_G : 4'h0;
//assign b = sprite_on ? CHAR_B : 4'h0;
endmodule
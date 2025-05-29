// ===================================================================
// Module: character_renderer
// Draws a solid‐color rectangle of size 64×240 at (x_pos,y_pos).
// ===================================================================
module character_renderer (
	input        video_on,     // from vga_background
	input  [9:0] hcnt, vcnt,   // pixel counters from vga_sync
	input  [9:0] x_pos,        // sprite top‐left X
	input  [9:0] y_pos,        // sprite top‐left Y
	input 		  attacking,
	input  [2:0] state,
	input        switch,
	output       sprite_on,    // high when inside the rectangle
	output [3:0] r, g, b       // 4-bit RGB for the sprite
);
// Character dimensions
localparam WIDTH = 64;
localparam HEIGHT = 240;
localparam BORDER_WIDTH = 2; // 2-pixel wide border


// within the 64×240 box -- in hurtbox?
wire in_x = (hcnt >= x_pos) && (hcnt < x_pos + WIDTH);
wire in_y = (vcnt >= y_pos) && (vcnt < y_pos + HEIGHT);
wire in_hurtbox = in_x && in_y;

// attack hitbox dimensions (extends forward during active frames)
wire in_hitbox_x = (hcnt >= x_pos + WIDTH) && (hcnt < x_pos + WIDTH + 32); // 32px hitbox extension(x)
wire in_hitbox_y = (vcnt >= y_pos + 80) && (vcnt < y_pos + 160);     // 80px hitbox extension(y) centered vertically
wire in_hitbox = in_hitbox_x && in_hitbox_y;


// Proper hurtbox outline (constrained to character area)
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



// determine if we're in active attack frames (from Table 1)
wire attack_active = attacking;

// Stick figure parameters (relative to hurtbox)
localparam HEAD_RADIUS = 20;
localparam BODY_LENGTH = 60;
localparam ARM_LENGTH = 40;
localparam LEG_LENGTH = 60;

// Stick figure coordinates (relative to character position)
wire [9:0] rel_x = hcnt - x_pos;
wire [9:0] rel_y = vcnt - y_pos;

// Head (circle)
wire [9:0] head_center_x = WIDTH/2;
wire [9:0] head_center_y = 40;
wire [19:0] head_dist_sq = (rel_x-head_center_x)*(rel_x-head_center_x) + 
									(rel_y-head_center_y)*(rel_y-head_center_y);
wire head_on = (head_dist_sq < (HEAD_RADIUS*HEAD_RADIUS));

// Body (vertical line)
wire body_on = (rel_x >= head_center_x-2) && (rel_x <= head_center_x+2) &&
				   (rel_y >= head_center_y+HEAD_RADIUS) && 
				   (rel_y <= head_center_y+HEAD_RADIUS+BODY_LENGTH);
					
// Arms (angled lines)
wire left_arm_on = (rel_y >= head_center_y+HEAD_RADIUS+20) &&
					    (rel_y <= head_center_y+HEAD_RADIUS+20+ARM_LENGTH) &&
					    (rel_x >= head_center_x - (rel_y-(head_center_y+HEAD_RADIUS+20))/2) &&
					    (rel_x <= head_center_x - (rel_y-(head_center_y+HEAD_RADIUS+20))/2 + 4);

wire right_arm_on = (rel_y >= head_center_y+HEAD_RADIUS+20) &&
					     (rel_y <= head_center_y+HEAD_RADIUS+20+ARM_LENGTH) &&
					     (rel_x >= head_center_x + (rel_y-(head_center_y+HEAD_RADIUS+20))/2 - 4) &&
					     (rel_x <= head_center_x + (rel_y-(head_center_y+HEAD_RADIUS+20))/2);

// Legs (angled lines)
wire left_leg_on = (rel_y >= head_center_y+HEAD_RADIUS+BODY_LENGTH) &&
					    (rel_y <= head_center_y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH) &&
					    (rel_x >= head_center_x - (rel_y-(head_center_y+HEAD_RADIUS+BODY_LENGTH))/3) &&
					    (rel_x <= head_center_x - (rel_y-(head_center_y+HEAD_RADIUS+BODY_LENGTH))/3 + 4);

wire right_leg_on = (rel_y >= head_center_y+HEAD_RADIUS+BODY_LENGTH) &&
					     (rel_y <= head_center_y+HEAD_RADIUS+BODY_LENGTH+LEG_LENGTH) &&
					     (rel_x >= head_center_x + (rel_y-(head_center_y+HEAD_RADIUS+BODY_LENGTH))/3 - 4) &&
					     (rel_x <= head_center_x + (rel_y-(head_center_y+HEAD_RADIUS+BODY_LENGTH))/3);

// Combined stick figure
wire stick_figure_on = in_hurtbox && (head_on || body_on || left_arm_on || right_arm_on || left_leg_on || right_leg_on);


// Final sprite detection (hurtbox outline, stick figure, or active hitbox)
assign sprite_on = video_on && ((switch && hurtbox_outline) || stick_figure_on || (attack_active && in_hitbox));
			  
// sprite is either body or active hitbox
//assign sprite_on = video_on && ( (in_hurtbox) || 
//										 (attack_active && in_hitbox_x && in_hitbox_y) );
//assign sprite_on = video_on && in_x && in_y;

// choose your character color here (e.g. bright red)
localparam [3:0] CHAR_R = 4'hF;
localparam [3:0] CHAR_G = 4'h0;
localparam [3:0] CHAR_B = 4'h0;
/*
localparam [3:0] HITBOX_R = 4'h0;
localparam [3:0] HITBOX_G = 4'hF;
localparam [3:0] HITBOX_B = 4'h0;
*/
  
reg [3:0] hit_r, hit_g, hit_b;
always @* begin
	case (state)
	4'd4: begin    // state == 4 → green
	hit_r = 4'h0; hit_g = 4'hF; hit_b = 4'h0;
	end
	4'd5: begin    // state == 5 → blue
		hit_r = 4'h0; hit_g = 4'h0; hit_b = 4'hF;
	end
	4'd6: begin    // state == 6 → orange (full red + mid green)
		hit_r = 4'hF; hit_g = 4'h8; hit_b = 4'h0;
	end
	default: begin // default hitbox color (green)
		hit_r = 4'h0; hit_g = 4'hF; hit_b = 4'h0;
	end
	endcase
end


// Output colors
assign r = sprite_on ? ((attack_active && in_hitbox) ? hit_r : 
						     ((switch && hurtbox_outline) ? 4'hF :       // red outline
						     (stick_figure_on ? 4'h0 : 4'h0))) : 4'h0; // Black stick figure

assign g = sprite_on ? ((attack_active && in_hitbox) ? hit_g : 
						     (switch && hurtbox_outline ? 4'h0 : 
						     (stick_figure_on ? 4'h0 : 4'h0))) : 4'h0;

assign b = sprite_on ? ((attack_active && in_hitbox) ? hit_b : 
						     (switch && hurtbox_outline ? 4'h0 : 
						     (stick_figure_on ? 4'hF : 4'h0))) : 4'h0;
/*
assign r = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_r : CHAR_R) : 4'h0;
assign g = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_g : CHAR_G) : 4'h0;
assign b = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_b : CHAR_B) : 4'h0;
*/

//assign r = sprite_on ? CHAR_R : 4'h0;
//assign g = sprite_on ? CHAR_G : 4'h0;
//assign b = sprite_on ? CHAR_B : 4'h0;
endmodule
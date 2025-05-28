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
	 //input  [3:0] attack_frame,
    output       sprite_on,    // high when inside the rectangle
    output [3:0] r, g, b       // 4-bit RGB for the sprite
);
  // within the 64×240 box?
  wire in_x = (hcnt >= x_pos) && (hcnt < x_pos + 64);
  wire in_y = (vcnt >= y_pos) && (vcnt < y_pos + 240);

  // attack hitbox dimensions (extends forward during active frames)
  wire in_hitbox_x = (hcnt >= x_pos + 64) && (hcnt < x_pos + 64 + 32); // 32px hitbox extension
  wire in_hitbox_y = (vcnt >= y_pos + 80) && (vcnt < y_pos + 160);     // centered vertically
  
  // determine if we're in active attack frames (from Table 1)
  wire attack_active = attacking; //&& 
                      //(attack_frame >= 5) && // startup frames
                      //(attack_frame < 7);    // active frames
  
  
  // sprite is either body or active hitbox
  assign sprite_on = video_on && ( (in_x && in_y) || 
                                  (attack_active && in_hitbox_x && in_hitbox_y) );
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
  
  assign r = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_r : CHAR_R) : 4'h0;
  assign g = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_g : CHAR_G) : 4'h0;
  assign b = sprite_on ? (attack_active && in_hitbox_x && in_hitbox_y ? hit_b : CHAR_B) : 4'h0;

  //assign r = sprite_on ? CHAR_R : 4'h0;
  //assign g = sprite_on ? CHAR_G : 4'h0;
  //assign b = sprite_on ? CHAR_B : 4'h0;
endmodule

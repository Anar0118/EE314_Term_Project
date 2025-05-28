// ===================================================================
// Module: vga_background
// Hooks into vga_sync and drives RGB with a simple horizontal gradient.
// ===================================================================
module vga_background (
    input        clk,        // 25 MHz pixel clock
    input        reset,      // synchronous reset
	 output       video_on,
    output       hsync,
    output       vsync,
    output [3:0] red,        // 4-bit per channel
    output [3:0] green,
    output [3:0] blue,
	 output [9:0] hcnt,
	 output [9:0] vcnt
);
  // instantiate sync generator
  //wire [9:0] hcnt, vcnt;
  
  vga_sync vsync_gen (
    .clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .video_on(video_on),
    .hcnt(hcnt),
    .vcnt(vcnt)
  );

localparam [3:0] MAX_INTENSITY = 4'hF;

assign red   = video_on ? MAX_INTENSITY : 4'h0;
assign green = video_on ? MAX_INTENSITY : 4'h0;
assign blue  = video_on ? MAX_INTENSITY : 4'h0;

  
/*
  // simple horizontal gradient: map hcnt [0..639] → color ramp
  // red ramps up, green ramps down, blue fixed at mid
  wire [3:0] grad_r = hcnt[9:6];            // top 4 bits of 0–639
  wire [3:0] grad_g = ~hcnt[9:6];           // inverted ramp
  localparam [3:0] BLUE_LEVEL = 4'h8;       // constant mid-blue

  // drive outputs only when video_on; otherwise blank
  assign red   = video_on ? grad_r      : 4'h0;
  assign green = video_on ? grad_g      : 4'h0;
  assign blue  = video_on ? BLUE_LEVEL  : 4'h0;
*/
endmodule
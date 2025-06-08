module countdown_renderer (
  input        video_on,
  input  [9:0] hcnt, vcnt,
  input  [1:0] cd_value, // 0..3
  output [3:0] r, g, b
);
  // center it
  localparam CX = 320-8, CY = 240-12;
  wire in_char;
  // stub: replace with actual bitmap test of (hcnt-CX,vcnt-CY) 
  // against a small ROM for each cd_value. For now:
  assign in_char = (hcnt>=CX && hcnt<CX+16 && vcnt>=CY && vcnt<CY+24);

  // white for the number/letters
  assign r = video_on && in_char ? 4'hF : 4'h0;
  assign g = video_on && in_char ? 4'hF : 4'h0;
  assign b = video_on && in_char ? 4'hF : 4'h0;
endmodule

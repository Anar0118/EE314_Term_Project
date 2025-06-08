module menu_renderer (
  input        video_on,
  input  [9:0] hcnt, vcnt,
  //input        select,
  input  [1:0] selected,  // 1 or 2
  output [3:0] r, g, b
);
  // box coords
  localparam [9:0] X1 = 10'd200, Y1 = 10'd180, W1 = 10'd240, H1 =  10'd60; // box for “1P”
  localparam [9:0] X2 = 10'd200, Y2 = 10'd260, W2 = 10'd240, H2 =  10'd60; // box for “2P”

  wire in1 = (hcnt>=X1 && hcnt<X1+W1 && vcnt>=Y1 && vcnt<Y1+H1);
  wire in2 = (hcnt>=X2 && hcnt<X2+W2 && vcnt>=Y2 && vcnt<Y2+H2);

  // highlight color vs normal
  wire [3:0] col_r = ( (selected==2'd1 && in1) || (selected==2'd2 && in2) ) ? 4'hF : 4'h7;
  wire [3:0] col_g = ( (selected==2'd1 && in1) || (selected==2'd2 && in2) ) ? 4'hF : 4'h7;
  wire [3:0] col_b = ( (selected==2'd1 && in1) || (selected==2'd2 && in2) ) ? 4'hF : 4'h7;

  assign r = video_on && (in1||in2) ? col_r : 4'h0;
  assign g = video_on && (in1||in2) ? col_g : 4'h0;
  assign b = video_on && (in1||in2) ? col_b : 4'h0;
endmodule

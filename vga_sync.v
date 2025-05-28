// ===================================================================
// Module: vga_sync
// Generates 640×480@60Hz timings (25 MHz pixel clock).
// Outputs pixel‐coordinates (hcnt, vcnt), video_on flag, hsync/vsync.
// ===================================================================
module vga_sync (
    input  clk,          // 25 MHz VGA pixel clock
    input  reset,        // synchronous reset
    output reg hsync,    // horizontal sync
    output reg vsync,    // vertical sync
    output      video_on,// high during visible pixels
    output [9:0] hcnt,   // 0..799 total horizontal pixels
    output [9:0] vcnt    // 0..524 total vertical lines
);

  // timing parameters for 640×480@60
  localparam H_VISIBLE   = 640;
  localparam H_FRONT_PORCH = 16;
  localparam H_SYNC_PULSE  = 96;
  localparam H_BACK_PORCH  = 48;
  localparam H_TOTAL     = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // 800

  localparam V_VISIBLE   = 480;
  localparam V_FRONT_PORCH = 10;
  localparam V_SYNC_PULSE  = 2;
  localparam V_BACK_PORCH  = 33;
  localparam V_TOTAL     = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // 525

  // horizontal & vertical counters
  reg [9:0] h_cnt, v_cnt;

  // generate h_cnt, v_cnt
  always @(posedge clk) begin
    if (reset) begin
      h_cnt <= 0;
      v_cnt <= 0;
    end else begin
      // next horizontal
      if (h_cnt == H_TOTAL-1) begin
        h_cnt <= 0;
        // next line
        if (v_cnt == V_TOTAL-1)
          v_cnt <= 0;
        else
          v_cnt <= v_cnt + 1;
      end else begin
        h_cnt <= h_cnt + 1;
      end
    end
  end

  // HSYNC: active low during sync pulse
  always @(posedge clk) begin
    if (reset)
      hsync <= 1;
    else if (h_cnt >= H_VISIBLE + H_FRONT_PORCH &&
             h_cnt <  H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE)
      hsync <= 0;
    else
      hsync <= 1;
  end

  // VSYNC: active low during sync pulse
  always @(posedge clk) begin
    if (reset)
      vsync <= 1;
    else if (v_cnt >= V_VISIBLE + V_FRONT_PORCH &&
             v_cnt <  V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE)
      vsync <= 0;
    else
      vsync <= 1;
  end

  // video_on when within visible region
  assign video_on = (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);

  // expose counters
  assign hcnt = h_cnt;
  assign vcnt = v_cnt;
endmodule

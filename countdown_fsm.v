module countdown_fsm (
  input        clk,      // 60 Hz
  input        reset,
  input        start,    // pulse when menu ends
  output reg [1:0] cd_value, // 0=“3”,1=“2”,2=“1”,3=“GO”
  output       active
);
  // duration of each stage in frames (e.g. 30 frames = 0.5 s)
  localparam DUR = 30;

  reg [5:0] timer;    // needs to count up to DUR
  reg       running;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      running  <= 1'b0;
      timer    <= 0;
      cd_value <= 2'd0;
    end else if (start) begin
      running  <= 1'b1;
      timer    <= 0;
      cd_value <= 2'd0;
    end else if (running) begin
      if (timer == DUR-1) begin
        timer <= 0;
        if (cd_value == 2'd3) begin
          running <= 1'b0; // done after “GO”
        end else begin
          cd_value <= cd_value + 2'd1;
        end
      end else begin
        timer <= timer + 6'd1;
      end
    end
  end

  assign active = running;
  
endmodule

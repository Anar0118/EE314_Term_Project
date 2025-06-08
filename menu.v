module menu(
  input        clk,        // 60 Hz
  input        reset,
  input        select,
  input        btn_confirm,// P1 presses to select mode or start
  output [1:0] game_mode,  // 1 = 1P ; 2 = 2P
  output       menu_active,
  output       countdown_active,
  output       play_active
);
  // state encoding
  localparam S_MENU      = 2'd0,
             S_COUNTDOWN = 2'd1,
             S_PLAY      = 2'd2;

  reg [1:0] state, nxt_state;
  reg [1:0] mode;

  // default next
  always@(*) begin
    nxt_state = state;
    // menu: toggle mode on each confirm press (edge-detect externally)
    case (state)
      S_MENU:      if (btn_confirm) nxt_state = S_COUNTDOWN;
      S_COUNTDOWN: if (!btn_confirm) nxt_state = S_PLAY; // when countdown_fsm done it deasserts start
      S_PLAY:      /* stays until reset */;
    endcase
  end

  // on each confirm in MENU, flip between 1 and 2
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= S_MENU;
      mode  <= 2'd1;  // default: 1P
    end else begin
      state <= nxt_state;
      //if (state == S_MENU && btn_confirm) mode <= (mode == 2'd1 ? 2'd2 : 2'd1);
		if (state == S_MENU) begin
			if (select == 1'd0) mode <= 2'd1;
			else if (select == 1'd1) mode <= 2'd2;
		end
    end
  end

  assign game_mode       = mode;
  assign menu_active     = (state == S_MENU);
  assign countdown_active= (state == S_COUNTDOWN);
  assign play_active     = (state == S_PLAY);

endmodule

module AudDSP(
    input           i_rst_n,
    input           i_clk,
    input           i_start,		// start or resume playing 
    input           i_pause,		// pause
    input           i_stop,			// stop
    input [2:0]     i_speed,		// 0~7 (represent 1~8)
    input           i_fast,			// 1 -> fast, 0 -> slow
    input           i_inte,			// 1 or 0 order interpolation
    input           i_daclrck,		
    input [15:0]    i_sram_data,	// the 16-bit data stored in sram
	output [15:0]	o_dac_data,		// AudPlayer will send this data to wm8731
	output [19:0]	o_sram_addr,	// sram address
    output          o_player_en		// enable AudPlayer
);

logic o_en_r, o_en_w;
logic [3:0]  state_r, state_w, mode_w, mode_r;
logic [19:0] o_addr_r, o_addr_w;
logic [15:0] prev_data_r, prev_data_w;
logic [15:0] o_data_r, o_data_w;
logic [3:0] cnt_r, cnt_w;
logic [2:0] i_speed_r, i_fast_r, i_inte_r;

localparam S_IDLE  = 0;
localparam S_FAST  = 2;
localparam S_SLOW0  = 3;
localparam S_SLOW1  = 1;
localparam S_WAIT1 = 4; // lrc = 0
localparam S_WAIT2 = 5; // lrc = 1
localparam S_BUFF  = 6; // BUF for 1 clk hold; 
localparam S_PAUS  = 7; 
localparam S_RUN   = 8;

// ouput assignments

assign o_dac_data = o_data_r;
assign o_sram_addr = o_addr_r;
assign o_player_en = o_en_r;

always begin
	@state_r
	$display("state: %1d", state_r, $time);
end
always begin
	@i_start
	$display("i_start: %1d", state_r, $time);
end

always_comb begin

    //default values
    state_w = state_r;
    o_addr_w = o_addr_r;
    prev_data_w = prev_data_r;
    o_data_w = o_data_r;
    cnt_w = cnt_r;

    // mode change
    if ( i_speed_r == 0 || i_fast_r ) begin
        mode_w = S_FAST;
    end else if ( i_inte_r ) begin
        mode_w = S_SLOW1;
    end else begin
        mode_w = S_SLOW0;
    end

    // signal processing
    case(state_r)
        S_FAST: begin
            prev_data_w = i_sram_data;
            o_addr_w = o_addr_r + 1 + i_speed_r;
            o_data_w = i_sram_data;
        end
        S_SLOW0: begin
            if (cnt_r < i_speed_r) begin     // interpolation (0)
                cnt_w = cnt_r + 1;
                o_data_w = prev_data_r;
            end else begin                      // play i_sram_data and change next addr
                cnt_w = 0;
                o_data_w = i_sram_data;
                o_addr_w = o_addr_r + 1;
            end

        end
        S_SLOW1: begin
            if (cnt_r < i_speed_r) begin     // interpolation (1)
                cnt_w = cnt_r + 1;
                o_data_w = cnt_r * (i_sram_data - prev_data_r) / (i_speed_r + 1) ;
            end else begin                      // play i_sram_data and change next addr
                cnt_w = 0;
                o_data_w = i_sram_data;
                o_addr_w = o_addr_r + 1;
            end
        end
    endcase

    // state switch & common 
    case(state_r)
        S_IDLE: begin // stop || rst_n
            if(i_start) begin // play key is pressed
                state_w = (i_daclrck) ? mode_r : S_WAIT2 ;
            end
            o_en_w = 0;
        end
        S_WAIT1: begin // wait for lrc to drop -> en = 1
            state_w = (!i_daclrck) ? S_WAIT2 : state_w;
            if (!i_daclrck) begin o_en_w = 1; end
        end
        S_WAIT2: begin // send data, wait for lrc to rise -> calculate
            state_w = i_daclrck ? mode_r : state_w;
        end
        S_FAST, S_SLOW0, S_SLOW1: begin
            state_w = S_WAIT1;
            if (i_pause) begin
                state_w = S_PAUS;
            end else if (i_stop) begin
                state_w = S_IDLE;
                o_addr_w = 0;
            end
        end
        S_PAUS: begin
            if (i_start) begin
                state_w = mode_r;
            end else if (i_stop) begin
                state_w = S_IDLE;
                o_addr_w = 0;
            end
            o_en_w = 0;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n ) begin
    if(!i_rst_n) begin
        i_speed_r   <= 0;
        i_fast_r    <= 0;
        i_inte_r    <= 0;
        state_r     <= S_IDLE;
        o_addr_r    <= 0;
        prev_data_r <= 0;
        o_data_r    <= 0;
        cnt_r       <= 0;
    end else begin
        if (state_r == S_WAIT2) begin   // change speed settings only in S_WAIT2
            i_speed_r   <= i_speed;
            i_fast_r    <= i_fast;
            i_inte_r    <= i_inte;
        end
        state_r     <= state_w;
        o_addr_r    <= o_addr_w;
        prev_data_r <= prev_data_w;
        o_data_r    <= o_data_w;
        cnt_r       <= cnt_w;
    end
end

endmodule


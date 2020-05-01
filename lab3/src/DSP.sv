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
    input signed [15:0] i_sram_data,	// the 16-bit data stored in sram
	output [15:0]	o_dac_data,		// AudPlayer will send this data to wm8731
	output [19:0]	o_sram_addr,	// sram address
    output          o_player_en		// enable AudPlayer
);

logic o_en_r, o_en_w;
logic [3:0]  state_r, state_w, mode_w, mode_r;
logic [19:0] o_addr_r, o_addr_w;
logic signed [15:0] prev_data_r, prev_data_w;
logic [15:0] o_data_r, o_data_w;
logic [3:0] cnt_r, cnt_w;
logic [2:0] i_speed_r, i_fast_r, i_inte_r;

localparam S_IDLE  = 0;
localparam S_FAST  = 2;
localparam S_SLOW  = 1;
localparam S_WAIT1 = 4; // lrc = 0
localparam S_WAIT2 = 5; // lrc = 1
localparam S_BUFF  = 6; // BUF for 1 clk hold; 
localparam S_PAUS  = 7; 
localparam S_RUN   = 8;

// ouput assignments

assign o_dac_data = o_data_r;
assign o_sram_addr = o_addr_r;
assign o_player_en = o_en_r;


always_comb begin

    //default values
    state_w = state_r;
    o_addr_w = o_addr_r;
    prev_data_w = prev_data_r;
    o_data_w = o_data_r;
    cnt_w = cnt_r;
    o_en_w = o_en_r;


    // mode change
    mode_w = (i_fast) ? S_FAST : S_SLOW;

    // signal processing
    case(state_r)
        S_FAST: begin
            prev_data_w = i_sram_data;
            o_addr_w = o_addr_r + 1 + i_speed_r;
            o_data_w = i_sram_data;
        end
        S_SLOW: begin
            if (cnt_r < i_speed) begin
                cnt_w = cnt_r + 1;
                   o_data_w = prev_data_r + i_inte ? (cnt_r+1) * (i_sram_data - prev_data_r) / (i_speed+1) : 0;
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
            state_w = (!i_daclrck) ? S_WAIT2 : state_r;
            if (!i_daclrck) begin o_en_w = 1; end
        end
        S_WAIT2: begin // send data, wait for lrc to rise -> calculate
            state_w = i_daclrck ? mode_r : state_r;
        end
        S_FAST, S_SLOW: begin
            state_w = S_WAIT1;
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
        default:;
    endcase
    if (state_r != S_IDLE) begin
        if (i_pause) begin
            state_w = S_PAUS;
        end else if (i_stop) begin
            state_w = S_IDLE;
            o_addr_w = 0;
            o_data_w = 0;
            o_en_w = 0;
        end
    end
end

always_ff @(posedge i_clk or negedge i_rst_n ) begin
    if(!i_rst_n) begin
        state_r     <= S_IDLE;
        mode_r      <= 0;
        o_addr_r    <= 0;
        prev_data_r <= 0;
        o_data_r    <= 0;
        cnt_r       <= 0;
        o_en_r      <= 0;
    end else begin
        state_r     <= state_w;
        mode_r      <= mode_w;
        o_addr_r    <= o_addr_w;
        prev_data_r <= prev_data_w;
        o_data_r    <= o_data_w;
        cnt_r       <= cnt_w;
        o_en_r      <= o_en_w;
    end
end

endmodule


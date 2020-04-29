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
logic [2:0]  state_r, state_w;
logic [19:0] o_addr_r, o_addr_w;
logic [15:0] o_data_r, o_data_w;

localparam S_IDLE = 0;
localparam S_NORM = 1; // normal mode
localparam S_FAST = 2;
localparam S_SLOW = 3;

// ouput assignments

assign o_dac_data = o_data_r;
assign o_sram_addr = o_addr_r;
assign o_player_en = o_en_r;


always_comb begin
    //default value
    state_w   = state_r;
    o_addr_w  = o_addr_r;
    o_en_w    = o_en_r;

    case(state_r)
        S_IDLE: begin
            if (i_start) begin
                o_en_w  = 0;
                state_w = S_NORM;
                o_data_w = i_sram_data;
                case(i_fast)
                    1'd1: begin // fast case
                        if(i_speed != 1) begin
                            state_w = S_FAST;
                        end
                    end
                    1'd0: begin // slow case
                        if(i_speed != 1) begin
                            state_w = S_SLOW;
                        end
                    end
                endcase
            end
        end

        S_NORM: begin
            if(i_pause || i_stop) begin
                state_w = S_IDLE;
            end
            else begin
                o_addr_w = o_addr_r + 1;
                o_en_w = 1'd1;
            end
        end

        S_FAST: begin

        end

        S_SLOW: begin

        end

    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state_r  = S_IDLE;
        o_en_r   = 0;
        o_data_r = 0;
        o_addr_r = 0;
    end
    else begin
        state_r  = state_w;
        o_en_r   = o_en_w;
        o_data_r = o_data_w;
        o_addr_r = o_addr_r;
    end
end

endmodule


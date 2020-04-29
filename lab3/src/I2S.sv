// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
module AudRecorder(
	input           i_rst_n, 
	input           i_clk,
	input           i_lrc,
	input           i_start,
	input           i_pause,
	input           i_stop,
	input           i_data,
	output [19:0]   o_address,
	output [15:0]   o_data
);

// === Params ===
localparam S_IDLE = 0;
localparam S_READ = 1;
localparam S_SAVE = 2;
localparam S_WAIT_1 = 3;
localparam S_WAIT_2 = 4;
localparam S_BUFF = 5;

// === Variables ===
logic [2:0]		state_r, state_w;
logic [19:0]	addr_r, addr_w;
logic [15:0]	data_r, data_w;
logic [3:0]		cnt_r, cnt_w;

// === Output Assignment ===
assign o_address = addr_r;
assign o_data 	 = data_r;

// === Combinational ===
always_comb begin

	// default values
	state_w = state_r;
	addr_w = addr_r;
	data_w = data_r;
	cnt_w = cnt_r;

	case(state_r)
		S_IDLE: begin
			if ( i_start ) begin
				state_w = S_WAIT_1;
			end
		end
		S_WAIT_1: begin 	// wait for LRC to rise
			if ( i_lrc == 1 ) begin state_w = S_WAIT_2; end
		end
		S_WAIT_2: begin 	// wait for LRC to drop
			if ( i_lrc == 0 ) begin state_w = S_READ; end
			cnt_w = 0;
		end
		/*
		S_BUFF: begin		// wait a cycle
			state_w = S_READ;
		end
		*/
		S_READ: begin		// read 16 bits
			data_w = { data_r[14:0], i_data };
			cnt_w = ( cnt_r == 15 ) ? 0 : cnt_r + 1;
			state_w = ( cnt_r == 15 ) ? S_SAVE : state_w;
		end
		S_SAVE: begin		// change address
			addr_w = addr_r + 1;
			state_w = S_WAIT_1;
			//$display("addr= %5x, data= %16b", addr_r, data_r);
		end
	endcase
	
	if ( i_pause || i_stop ) begin
		state_w = S_IDLE;
	end

	if ( i_stop ) begin
		addr_w = 0;
	end

end

// === Sequential ===
always_ff @ ( posedge i_clk or negedge i_rst_n ) begin
	if ( !i_rst_n ) begin
		cnt_r <= 0;
		addr_r <= 0;
		data_r <= 0;
		state_r <= S_IDLE;
	end
	else begin
		cnt_r <= cnt_w;
		addr_r <= addr_w;
		data_r <= data_w;
		state_r <= state_w;
		
	end

end

endmodule

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
module AudPlayer(
	input           i_rst_n,
	input           i_bclk,
	input           i_daclrck,
	input           i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0]    i_dac_data, //dac_data
	output          o_aud_dacdat
);

// === params ===
localparam S_WAIT_1 = 1;
localparam S_WAIT_2 = 2;
localparam S_SEND = 0;

// === variables ===
logic [1:0]		state_r, state_w;
logic [15:0]	data_r, data_w;
logic [3:0]		cnt_r, cnt_w;

// === output assignment ===
assign o_aud_dacdat = data_r[15];

// === combinational ===

always_comb begin

	// default values
	state_w = state_r; 
	data_w = data_r;
	cnt_w = cnt_r;

	if ( i_en ) begin
		case(state_r)
			S_WAIT_1: begin		// wait for lrc to rise
				state_w = ( i_daclrck == 1 ) ? S_WAIT_2 : state_w;
			end
			S_WAIT_2: begin		// wait for lrc to drop
				state_w = ( i_daclrck == 0 ) ? S_SEND : state_w;
				cnt_w = 0;
				data_w = i_dac_data;
			end
			S_SEND: begin
				state_w = (cnt_r == 15) ? S_WAIT_1 : state_w;
				cnt_w = (cnt_r == 15) ? 0 : cnt_r + 1;
				data_w = data_r << 1;
			end
		endcase
	end else begin
		state_w = S_WAIT_1;
	end
end

// === sequential ===

always_ff @(posedge i_bclk or negedge i_rst_n) begin
	if ( !i_rst_n ) begin
		cnt_r <= 0;
		data_r <= 0;
		state_r <= S_WAIT_2;
	end else begin
		cnt_r <= cnt_w;
		data_r <= data_w;
		state_r <= state_w;
	end
end

endmodule
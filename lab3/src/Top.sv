module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,			// record/pause
	input i_key_1,			// play/pause
	input i_key_2,			// stop
	input [3:0] i_speed,	// speed (0~8)
	input i_fast,			// fast/slow
	input i_inte,			// 1/0 interpolation
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT

	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// === params ===
parameter S_INIT		= 3'b000;
parameter S_IDLE		= 3'b111;

parameter S_PLAY       	= 3'b001;
parameter S_PLAYP 		= 3'b010;

parameter S_RECD       	= 3'b101;
parameter S_RECDP 		= 3'b110;

// === variables ===
logic [2:0] 	state_r, state_w;
logic [19:0]	addr_end_r, addr_end_w;		// the end address of the audio
logic [2:0]		i_speed_r, speed_r, speed_w;
logic 			i_inte_r ,i_fast_r;

// === output assignments ===
logic i2c_oen, i2c_sdat;
logic [19:0] 	addr_record, addr_play;
logic [15:0] 	data_record, data_play, dac_data;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;


assign o_SRAM_ADDR = (S_RECD) ? addr_record : addr_play;
assign io_SRAM_DQ  = (S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// === submodule i/o ===

// i2c
logic i2c_start, i2c_finished;

// dsp
logic dsp_start, dsp_pause, dsp_stop;

// player
logic player_en;

// recorder
logic recorder_start, recorder_pause, recorder_stop;

// display
logic [19:0]	display_addr;
assign display_addr = (S_RECD || S_RECDP) ? addr_record : addr_play;


// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100K),
	.i_start(i2c_start),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(dsp_start),
	.i_pause(dsp_pause),
	.i_stop(dsp_stop),
	.i_speed(speed_r),
	.i_fast(i_fast_r),
	.i_inte(i_inte_r),
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play),
	.o_player_en(player_en)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);

/*
Display display0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_addr(display_addr),
	.i_addr_end(addr_end_r),
	.i_state(state_r),
	.i_speed(speed_r),
	.i_fast(i_fast_r),
	.i_inte(i_inte_r)
);*/

always_comb begin

	// default values
	i2c_start = 0;
	recorder_start = 0;
	recorder_pause = 0;
	recorder_stop = 0;
	dsp_start = 0;
	dsp_pause = 0;
	dsp_stop = 0;

	speed_w = ( i_speed_r >= 1 && i_speed_r <= 8 ) ? i_speed_r-1 : 0;

	state_w = state_r;
	addr_end_w = addr_end_r;

	// rec, play
	case(state_r)
		S_INIT: begin
			state_w =  (i2c_finished) ? S_IDLE : state_w;
			i2c_start = 1;
		end
		S_IDLE: begin
			if (i_key_0) begin 				// start recording
				recorder_start = 1;
				addr_end_w = 0;
			end else if (i_key_1) begin		// start playing
			end
		end
		S_RECD: begin
			if (i_key_0) begin				// pause
				recorder_pause = 1;
				addr_end_w = addr_record;
				state_w = S_RECDP;
			end
		end
		S_RECDP: begin
			if (i_key_0) begin				// resume recording
				recorder_start = 1;
				state_w = S_RECD;
			end
		end
		S_PLAY: begin
			if (i_key_1) begin				// pause
				state_w = S_PLAYP;
				dsp_pause = 1;
			end
		end
		S_PLAYP: begin
			if (i_key_1) begin				// resume 
				state_w = S_PLAY;
				dsp_start = 1;
			end
		end
	endcase

	// stop
	case(state_r)
		S_RECD, S_RECDP: begin
			if (i_key_2) begin		// stop recording
				state_w = S_IDLE;
				recorder_stop = 1;
			end
		end
		S_PLAY, S_PLAYP: begin
			if (i_key_2) begin		// stop playing
				state_w = S_IDLE;
				dsp_stop = 1;
			end
		end
	endcase
end

always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r 	<= S_IDLE;
		addr_end_r 	<= 0;
		speed_r 	<= 0;
		i_speed_r 	<= 0;
		i_inte_r	<= 0;
		i_fast_r	<= 0;
	end
	else begin
		state_r 	<= state_w;
		addr_end_r 	<= addr_end_w;
		speed_r 	<= speed_w;
		i_speed_r 	<= i_speed;
		i_inte_r	<= i_inte;
		i_fast_r	<= i_fast;
	end
end

endmodule
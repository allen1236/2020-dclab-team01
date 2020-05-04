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
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [23:0] o_sev,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	output [25:0]	o_volume
);

// === params ===
localparam S_IDLE		= 1;
localparam S_PLAY       = 2;
localparam S_PLAYP 		= 3;
localparam S_RECD       = 4;
localparam S_RECDP 		= 5;
localparam S_BUFF		= 0;
localparam S_INIT		= 6;

localparam VOLUME_DROP = 16'd20000;
localparam VOLUME_BAR  = 56'b11111111111111111111111110000000000000000000000000000000;

// === variables ===
logic [2:0] 	state_r, state_w, state_des_r, state_des_w;
logic [19:0]	addr_end_r, addr_end_w;		// the end address of the audio
logic [2:0]		speed_r, speed_w;

logic [15:0]	cnt_r, cnt_w;
logic [4:0]		max_r, max_w;
logic signed [15:0] 	volume_data;
logic [15:0] 	volume;

// === output assignments ===
logic i2c_oen, i2c_sdat;
logic [19:0] 	addr_record, addr_play;
logic [15:0] 	data_record, data_play, dac_data;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r==S_RECD || state_r == S_RECDP) ? addr_record : addr_play;
assign io_SRAM_DQ  = (state_r==S_RECD || state_r == S_RECDP) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r==S_RECD || state_r == S_RECDP) ? 16'd0 : io_SRAM_DQ; // sram_dq as input
assign volume_data = ( state_r == S_RECD ) ? data_record : dac_data;
assign volume = ( volume_data > 0 ) ?  volume_data : (-volume_data);

assign o_SRAM_WE_N = (state_r==S_RECD || state_r == S_RECDP) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;


// === submodule i/o ===

// i2c
logic i2c_start, i2c_finished;

// dsp
logic dsp_pause, dsp_stop;

// player
logic player_en;

// recorder
logic recorder_start, recorder_pause, recorder_stop;

// seven decoder
logic [5:0] sev0, sev1, sev2, sev3;
assign sev0 = addr_record / 32000;
assign sev1 = addr_play / 32000;
assign sev2 = i2c_finished;
//assign sev3 = '0;
assign o_sev = { sev0, sev1, sev2, sev3 };
assign o_volume = VOLUME_BAR[max_r+:25];


// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(1),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen), // you are outputing (you are not outputing only when you are "ack"ing.)
	.o_sev(sev3)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(state_r==S_PLAY),
	.i_pause(state_r==S_PLAYP),
	.i_stop(state_r==S_IDLE),
	.i_speed(speed_r),
	.i_fast(i_fast),
	.i_inte(i_inte),
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
	.i_start(state_r==S_RECD),
	.i_pause(state_r==S_RECDP),
	.i_stop(state_r==S_IDLE),
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

always begin
	//@o_AUD_DACDAT
	//$display("output data: %1b", o_AUD_DACDAT, $time);
	//@o_SRAM_ADDR;
	//$display("end address: %2d, addr_play: %2d, sram_addr: %2d", addr_end_r, addr_play, o_SRAM_ADDR);
end

always_comb begin
	cnt_w = (cnt_r >= VOLUME_DROP) ? 0 : cnt_r + 1;
	if ( volume[14:10] > max_r ) max_w = volume[14:10];
	else if (cnt_r >= VOLUME_DROP) max_w = max_r - 1;
	else max_w = max_r;
end


always_comb begin

	// default values

	speed_w = ( i_speed >= 1 && i_speed <= 8 ) ? i_speed-1 : 0;

	state_w = state_r;
	state_des_w = state_des_r;
	addr_end_w = addr_end_r;

	// rec, play
	case(state_r)
		S_INIT: begin
			if (i2c_finished) begin
				state_w = S_IDLE;
			end
		end
		S_IDLE: begin
			if (i_key_0) begin 				// start recording
				addr_end_w = 0;
				state_des_w = S_RECD;
				state_w = S_BUFF;
			end else if (i_key_1) begin		// start playing
				state_des_w = S_PLAY;
				state_w = S_BUFF;

			end
		end
		S_RECD: begin
			if (i_key_0) begin				// pause
				state_des_w = S_RECDP;
				state_w = S_BUFF;
			end
			addr_end_w = addr_record;
		end
		S_RECDP: begin
			if (i_key_0) begin				// resume recording
				state_des_w = S_RECD;
				state_w = S_BUFF;
			end
		end
		S_PLAY: begin
			if (i_key_1) begin				// pause
				state_des_w = S_PLAYP;
				state_w = S_BUFF;
			end
		end
		S_PLAYP: begin
			if (i_key_1) begin				// resume 
				state_des_w = S_PLAY;
				state_w = S_BUFF;
			end
		end
		S_BUFF: begin
			if (!i_key_0 && !i_key_1) begin
				state_w = state_des_r;
			end
		end
	endcase

	// stop
	case(state_r)
		S_RECD, S_RECDP: begin
			if (i_key_2) begin		// stop recording
				state_w = S_IDLE;
			end
		end
		S_PLAY, S_PLAYP: begin
			if (i_key_2 || speed_r + addr_play >= addr_end_r) begin		// stop playing
				state_w = S_IDLE;
			end
		end
	endcase
end

always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r 	<= S_INIT;
		state_des_r <= 0;
		addr_end_r 	<= 0;
		speed_r 	<= 0;
		cnt_r 		<= 0;
		max_r		<= 0;
	end
	else begin
		state_r 	<= state_w;
		state_des_r <= state_des_w;
		addr_end_r 	<= addr_end_w;
		speed_r 	<= speed_w;
		cnt_r		<= cnt_w;
		max_r		<= max_w;
	end
end

endmodule
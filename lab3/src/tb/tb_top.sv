`timescale 1ns/10ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam NUM_BYTE = 14;
	logic clk;

	initial clk = 0;
	always #HCLK clk = ~clk;

	logic rst_n, recd, play, stop;
	logic [3:0] spd;
	logic fast, inte;

	logic [19:0] sram_addr;
	logic [15:0] sram_data;
	logic sram_write;
	logic [15:0] sram_storage[63:0];

	logic recd_data, play_data, lrc;
	logic [5:0] recd_time, play_time;
	logic [15:0] wm_data, wm_data_r;

	logic null_logic;

	int a;


	Top top0(
		.i_rst_n(rst_n),
		.i_clk(clk),
		.i_key_0(rec),
		.i_key_1(play),
		.i_key_2(stop),
		.i_speed(spd), // design how user can decide mode on your own
		.i_fast(fast),
		.i_inte(inte),

		// AudDSP and SRAM
		.o_SRAM_ADDR(sram_addr), // [19:0]
		.io_SRAM_DQ(sram_data), // [15:0]
		.o_SRAM_WE_N(sram_write),
		.o_SRAM_CE_N(null_logic),
		.o_SRAM_OE_N(null_logic),
		.o_SRAM_LB_N(null_logic),
		.o_SRAM_UB_N(null_logic),
		
		// I2C
		.i_clk_100k(clk),
		.o_I2C_SCLK(null_logic),
		.io_I2C_SDAT(null_logic),
		
		// AudPlayer
		.i_AUD_ADCDAT(recd_data),
		.i_AUD_ADCLRCK(lrc),
		.i_AUD_BCLK(clk),
		.i_AUD_DACLRCK(lrc),
		.o_AUD_DACDAT(play_data),

		// SEVENDECODER (optional display)
		.o_record_time(recd_time),
		.o_play_time(play_time)

		// LCD (optional display)
		// .i_clk_800k(CLK_800K),
		// .o_LCD_DATA(LCD_DATA), // [7:0]
		// .o_LCD_EN(LCD_EN),
		// .o_LCD_RS(LCD_RS),
		// .o_LCD_RW(LCD_RW),
		// .o_LCD_ON(LCD_ON),
		// .o_LCD_BLON(LCD_BLON),

		// LED
		// .o_ledg(LEDG), // [8:0]
		// .o_ledr(LEDR) // [17:0]
	);

	task sram( input write, input [19:0] addr, inout [15:0] data );
		if ( write ) begin
			sram_storage[addr] = data;
		end else begin
			data = sram_storage[addr];
		end
	endtask
	task wm8731( input i_clk, input i_bit, input i_lrc, output o_bit);
		while (1) begin
			if ( !i_lrc ) begin
				#(HCLK);
				for ( int j = 0; j < 16; j++ ) begin
					@(negedge clk)
						o_bit = ( j == 0 || j == 15 || j == a ) ? 1 : 0;
						wm_data[15-j] = i_bit;
				end
				a = (a == 14)  ? 1 : a+1;
				wm_data_r = wm_data;
			end
		end
	endtask

	task press(output key);
		key = 1;
		#(3*CLK);
		key = 0;
	endtask

	initial begin
		rst_n = 1;
		#(1*CLK);
		rst_n = 0;
		#(2*CLK);
		rst_n = 1;
		#(1*CLK);
		@(posedge clk)

		press(recd);
		#(9*CLK);
		press(recd);
		#(9*CLK);
		press(recd);
		#(9*CLK);
		press(stop);
		#(9*CLK);

		press(play);
		#(9*CLK);
		press(play);
		#(9*CLK);
		press(play);
		#(9*CLK);
		press(stop);
		#(9*CLK);

		$finish;
	end

	initial begin
		$monitor("playing: %16b", wm_data_r );
	end

	initial begin
		sram( sram_write, sram_addr, sram_data );
	end
	
	initial begin
		a = 1;
		wm8731(recd_data, lrc, play_data);
	end

	initial begin
		@(negedge clk)
		while (1) begin
			lrc = 1;
			#(20*CLK);
			lrc = 0;
			#(20*CLK);
		end
	end

	initial begin
		for (int j=0; j < 8; j++) begin
			#(10*CLK)
			$display(sram_storage);
		end
	end

	initial begin
		#(500000*CLK);
		$display("Too slow, abort.");
		$finish;
	end

endmodule

`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam NUM_BYTE = 14;
	logic clk;

	localparam SRAM_SIZE = 1024;

	initial clk = 0;
	always #HCLK clk = ~clk;

	logic rst_n, recd, play, stop;
	logic [3:0] spd;
	logic fast, inte;

	int sram_addr;
	logic [15:0] sram_data;
	logic sram_write;
	int sram_storage[SRAM_SIZE];

	logic recd_data, play_data, lrc;
	logic [5:0] recd_time, play_time;
	logic signed [15:0] wm_data, wm_data_r, wm_data_last;

	wire [15:0] sram_data_w;
	wire lrc_w, clk_w;
	wire [23:0] sev;
	assign lrc_w = lrc;
	assign clk_w = clk;
	assign sram_data_w = (sram_write) ? sram_data :'z;

	wire null_logic;

	logic [15:0] a;


	Top top0(
		.i_rst_n(rst_n),
		.i_clk(clk),
		.i_key_0(recd),
		.i_key_1(play),
		.i_key_2(stop),
		.i_speed(spd), // design how user can decide mode on your own
		.i_fast(fast),
		.i_inte(inte),

		// AudDSP and SRAM
		.o_SRAM_ADDR(sram_addr), // [19:0]
		.io_SRAM_DQ(sram_data_w), // [15:0]
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
		.i_AUD_ADCLRCK(lrc_w),
		.i_AUD_BCLK(clk_w),
		.i_AUD_DACLRCK(lrc_w),
		.o_AUD_DACDAT(play_data),

		// SEVENDECODER (optional display)
		.o_sev(sev)

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

	task wm8731();
		a = 0;
		while (1) begin
			@(negedge lrc)
			#(CLK);
			for ( int j = 0; j < 16; j++ ) begin
				recd_data = a[15-j];
				wm_data[15-j] = play_data;
				#(CLK);
			end
			a =  a + 16'h0800;
			wm_data_last = wm_data_r;
			wm_data_r = wm_data;
		end
	endtask


	always_comb begin
		if ( sram_write ) begin
			sram_data = sram_storage[sram_addr];
		end else begin
			sram_storage[sram_addr] = sram_data_w;
		end
	end

	initial begin
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars;
		rst_n = 1;
		#(1*CLK);
		rst_n = 0;
		#(2*CLK);
		rst_n = 1;
		#(1*CLK);
		spd = 5;
		fast = 0;
		inte = 1;
		#(2*CLK);

		@(posedge clk)
		$display("=========== start ===========");

		stop = 0;
		play = 0;
		recd = 1;
		#(3*CLK);
		recd = 0;
		#(200*40*CLK);
		stop = 1;
		#(3*CLK);
		stop = 0;
		#(10*40*CLK);

		$display("=========== sram begin ===========");
		for( int j=0; j < SRAM_SIZE; j++ ) begin
			$display( "sram[%2d] %16b", j,  sram_storage[j]);
		end
		$display("=========== sram end ===========");

		play = 1;
		#(3*CLK);
		play = 0;
		#(20*40*CLK);

		#(800*40*CLK);
		
		$display("========== finish ===========");

		$finish;
	end

	initial begin
		$monitor("%6d: %4d (%4d)",$time/40, wm_data_r, wm_data_r - wm_data_last );
		//$monitor("sending: %1b", play_data );
		//$monitor("state= %1d (%6d)", hex2, $time );
		//$monitor("input: %1b", recd_data, $time);
	end

	//always @sram_addr
	//$display("addr= %2d, data=%16b", sram_addr, sram_data_w ,$time);

	initial begin
		a = 1;
		wm8731();
	end

	initial begin
		while (1) begin
			lrc = 1;
			#(20*CLK);
			lrc = 0;
			#(20*CLK);
		end
	end

	initial begin
		#(500000*CLK);
		$display("Too slow, abort.");
		$finish;
	end

endmodule

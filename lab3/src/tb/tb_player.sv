`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam NUM_BYTE = 14;
	logic clk;

	initial clk = 0;
	always #HCLK clk = ~clk;

	logic rst_n, start, pause, stop;
	logic i_lrc, i_data;
	logic [19:0] o_addr;
	logic [15:0] o_data;

	AudRecorder rec0(
		.i_rst_n(rst_n), 
		.i_clk(clk),
		.i_lrc(i_lrc),
		.i_start(start),
		.i_pause(pause),
		.i_stop(stop),
		.i_data(i_data),
		.o_address(o_addr),
		.o_data(o_data)
	);

	initial begin
		rst_n = 1;
		#(1*CLK);
		rst_n = 0;
		#(2*CLK);
		rst_n = 1;
		#(1*CLK);
		i_lrc = 1;
		@(posedge clk);
		start <= 1;
		i_data = 0;
		@(posedge clk);
		start <= 0;
		for (int j = 0; j < NUM_BYTE; j++) begin
			@(negedge clk)
			i_lrc = 1;
			#(20*CLK);

			@(negedge clk);
			i_lrc = 0;

			@(negedge clk);
			i_data = 1;
			for (int k = 0; k < 14; k++ ) begin
				@(negedge clk);
				if ( j == k ) begin i_data <= 1; end
				else begin i_data <= 0; end
			end
			@(negedge clk);
			i_data = 1;
			#(4*CLK);
		end
		$finish;
	end

	initial begin
		for ( int j = 0; j < NUM_BYTE; j++ ) begin
			@o_addr
			$display("addr= %5x, data= %16b", o_addr, o_data);

		end
	end

	initial begin
		#(500000*CLK);
		$display("Too slow, abort.");
		$finish;
	end

endmodule

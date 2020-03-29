`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] r;
	logic [247:0] golden;
	integer fp_e, fp_d;

	ModuloProduct test(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_n(256'hCA3586E7EA485F3B0A222A4C79F7DD12E85388ECCDEE4035940D774C029CF831),
		.i_a(257'b1<<256),
		.i_b(256'hc6b662ecb173c53cc7bb4212057f9c0ba283e000b98c9dcf5feaee7d6c933dfb),
		.o_result(r),
		.o_finish(fin)
	);

	initial begin
		$fsdbDumpfile("lab2.fsdb");
		$fsdbDumpvars;
		rst = 1;
		#(2*CLK)
		rst = 0;
		for (int j = 0; j < 10; j++) begin
			@(posedge clk);
		end
		start_cal <= 1;
		@(posedge clk)
		start_cal <= 0;
		@(posedge fin)
		$display("=========");
		$display("%64d", r);
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule

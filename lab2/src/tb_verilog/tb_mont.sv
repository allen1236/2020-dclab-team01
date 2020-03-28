`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] a, b, n, r;
	logic [247:0] golden;
	integer fp_e, fp_d;

	Montgomery test(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_n(256'd72),
		.i_a(256'd5),
		.i_b(256'd32), // 29 * 2^256
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
		$display("result: %d (answer: %d)", r, 1);
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
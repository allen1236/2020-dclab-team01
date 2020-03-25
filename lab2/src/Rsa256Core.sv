module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
/*========== States ==========*/
parameter S_IDLE = 2'd0;
parameter S_PREP = 2'd1;
parameter S_MONT = 2'd2;
parameter S_CALC = 2'd3;

/*========== Parameters ==========*/

/*========== Output Buffers ==========*/

/*========== Variables ==========*/
logic [1:0]		state_r, state_w;
logic [255:0]	text_r, text_w;

/*========== Output Assignments ==========*/



/*============this is for test only Modulo product==============*/

ModuloProduct test(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_start(i_start),
	.i_n(i_n),
	.i_a(i_a),
	.i_b(i_d),
	.o_result(o_a_pow_d),
	.o_finish(o_finished)
); // a*d mod n


/*========== Compinational Circuits ==========*/
always_comb begin
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin
end

endmodule

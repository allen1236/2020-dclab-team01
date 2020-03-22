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

/*========== Compinational Circuits ==========*/
always_comb begin
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or negedge i_rst_n) begin
end

endmodule

module ModuloProduct{
	input			i_clk,
	input			i_rst,
	input			i_start,
	input [255:0]	i_n,
	input [255:0]	i_a,
	input [255:0]	i_b,
	output [255:0]	o_result,
	output			o_finish
};

/*========== States ==========*/

/*========== Parameters ==========*/

/*========== Output Buffers ==========*/

/*========== Variables ==========*/

/*========== Output Assignments ==========*/

/*========== Compinational Circuits ==========*/
always_comb begin
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or negedge i_rst_n) begin
end

endmodule

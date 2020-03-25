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
parameter S_IDLE = 1'd0;
parameter S_CALC = 1'd1;
/*========== Parameters ==========*/
parameter [6:0] K = 7'd255;

/*========== Output Buffers ==========*/
logic[255:0] o_result_w, o_result_r;
logic 		 o_finish_w, o_finish_w;

/*========== Variables ==========*/
logic [1:0] state_w, state_r;
logic [6:0] counter_w, counter_r;

/*========== Output Assignments ==========*/

assign o_result = o_result_r;
assign o_finish = o_finish_r;

/*========== Compinational Circuits ==========*/
always_comb begin
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin
end

endmodule

module ModuloProduct(
	input			i_clk,
	input			i_rst,
	input			i_start,
	input [255:0]	i_n,
	input [255:0]	i_a,
	input [255:0]	i_b,
	output [255:0]	o_result,
	output			o_finish
);

/*========== States ==========*/
parameter S_IDLE = 1'd0;
parameter S_CALC = 1'd1;
/*========== Parameters ==========*/
parameter [6:0] K = 7'd255;

/*========== Output Buffers ==========*/
logic[255:0] o_result_w, o_result_r;
logic 		 o_finish_w, o_finish_r;

/*========== Variables ==========*/
logic [1:0] state_w, state_r;
logic [6:0] counter_w, counter_r;
logic [255:0] mult_w, mult_r;

/*========== Output Assignments ==========*/
assign o_result = o_result_r;
assign o_finish = o_finish_r;

/*========== Compinational Circuits ==========*/
always_comb begin
	// default value
	o_result_w = o_result_r;
	o_finish_w = o_finish_r;
	state_w    = state_r;
	mult_w     = mult_r;
	counter_w  = counter_r;

	case(state_r)

	S_IDLE: begin
		counter_w = 7'd0;
		if(i_start) begin
			state_w = S_CALC;
			mult_w = i_b;
			o_result_w = 1'd0;
		end
	end

	S_CALC: begin
		counter_w = counter_r + 1;
		if( counter_r == K) begin
			state_w = S_IDLE;
			o_finish_w = 1'd1;
		end
		else begin
			if( i_a[counter_r]==1 ) begin
				o_result_w = ( o_result_r+mult_r >= i_n) ? o_result_r+mult_r-i_n : o_result_r+i_n;
			end
		end
		mult_w = (mult_r+mult_r > i_n) ? mult_r+mult_r-i_n : mult_r+mult_r;
	end
	endcase
	
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin

	if(i_rst) begin
		counter_r  <= 0;
		state_r    <= S_IDLE;
		mult_r     <= 0;
		o_result_r <= 0;
		o_finish_r <= 0;
	end
	else begin
		counter_r  <= counter_w;
		state_r    <= state_w;
		mult_r     <= mult_w;
		o_result_r <= o_result_w;
		o_finish_r <= o_finish_w;

	end
end

endmodule

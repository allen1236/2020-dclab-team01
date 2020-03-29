module Rsa256Core2 (
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
parameter STEP = 256;
parameter basis = (257'b1 << 256);

/*========== Output Buffers ==========*/

/*========== Variables ==========*/
logic [1:0] 	state_r, state_w;
logic 			Mont_start_r, MP_start_r;
logic 			Mont_start_w, MP_start_w;
logic [256:0] 	n_r, n_w, d_r, d_w;
logic [256:0] 	a_r, a_w;
logic [256:0] 	t_r, t_w, r_r, r_w;
logic			o_finished_r, o_finished_w;
logic [255:0]	o_result_r, o_result_w;
logic [15:0] 	cnt_r, cnt_w;

logic 			Mont_start_in, MP_start_in;
logic 			Mont_reset, MP_reset;
logic [256:0]	n_in, d_in, t_in, r_in;
logic [256:0]	a_in;
logic [255:0] 	MP_result, MT_result, TT_result;
logic 			MP_finish_out, MT_finish_out, TT_finish_out;
logic 			MP_finish_r, MT_finish_r, TT_finish_r;

/*========== Output Assignments ==========*/
assign o_finished = o_finished_r;
assign o_a_pow_d = o_result_r;

assign n_in = n_r;
assign a_in = a_r;
assign d_in = d_r;
assign t_in = t_r;
assign r_in = r_r;

assign  MP_start_in = MP_start_r;
assign  Mont_start_in = Mont_start_r;

/*========== Compinational Circuits ==========*/

ModuloProduct MP(
	.i_clk(i_clk), 
	.i_rst(i_rst || MP_reset), 
	.i_start(MP_start_in), 
	.i_n(n_in), 
	.i_a(a_in), 
	.i_b(basis), 
	.o_result(MP_result), /*y under basis 2^256*/
	.o_finish(MP_finish_out)
);
	
Montgomery MT(
	.i_clk(i_clk),
	.i_rst(i_rst || Mont_reset),
	.i_start( Mont_start_in ),
	.i_n(n_in),
	.i_a(r_in),
	.i_b(t_in),
	.o_result(MT_result),
	.o_finish(MT_finish_out)
);

Montgomery TT(
	.i_clk(i_clk),
	.i_rst(i_rst || Mont_reset),
	.i_start( Mont_start_in ),
	.i_n(n_in),
	.i_a(t_in), /*t in the slide*/
	.i_b(t_in), /*t in the slide*/
	.o_result(TT_result),
	.o_finish(TT_finish_out)
);

always_comb begin

state_w = state_r;
n_w = n_r;
a_w = a_r;
d_w = d_r;
t_w = t_r;
r_w = r_r;
o_finished_w = o_finished_r;
o_result_w = o_result_r;
cnt_w = cnt_r;
MP_start_w = 0;
Mont_start_w = 0;
Mont_reset = 0;
MP_reset = 0;

case(state_r)

	S_IDLE:begin
		if ( i_start ) begin 
			n_w = i_n;
			a_w = i_a;
			d_w = i_d;
			$display("=====begin=====");
			$display("n = %x", n_w );
			$display("a = %x", a_w );
			$display("d = %x", d_w );
			r_w = 1;
			state_w = S_PREP;
			MP_start_w = 1;
			o_finished_w = 0;
		end
	end

	S_PREP:begin
		if ( MP_finish_r ) begin
			t_w = MP_result;
			//$display("t = a * 2^256 mod n = %x", MP_result );
			state_w = S_MONT;
			Mont_reset = 1;
			Mont_start_w = 1;
			cnt_w = 0;
		end
	end

	S_MONT:begin
		if ( MT_finish_r && TT_finish_r ) begin
			r_w = ( d_r[cnt_r] ) ? MT_result : r_r;
			//$display( "%1d loop %3d, t = %64x", d_r[cnt_r], cnt_r, t_r );
			t_w = TT_result;
			state_w = S_CALC;
			/*
			$display("=====");
			$display("counter = %d", cnt_r);
			$display("finish Mont TT = %d", TT_result);
			$display("finish Mont MT = %d", MT_result);
			$display("=====");
			*/
		end
	end

	S_CALC:begin
		if ( cnt_r == 16'd255 ) begin
			o_result_w = r_r;
			o_finished_w = 1;
			state_w = S_IDLE;
			Mont_reset = 1;
			MP_reset = 1;
			$display("===== done =====");
		end else begin
			cnt_w = cnt_r + 1;
			state_w = S_MONT;
			Mont_reset = 1;
			Mont_start_w = 1;
		end
	end

endcase

end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin

	if(i_rst) begin
		state_r <= S_IDLE;
		n_r <= 0;
		a_r <= 0;
		d_r <= 0;
		t_r <= 0;
		r_r <= 0;
		o_finished_r <= 0;
		o_result_r <= 0;
		cnt_r <= 0;
		MP_start_r <= 0;
		Mont_start_r <= 0;
		MP_finish_r <= 0;
		MT_finish_r <= 0;
		TT_finish_r <= 0;
	end
	else begin
		state_r <= state_w;
		n_r <= n_w;
		a_r <= a_w;
		d_r <= d_w;
		t_r <= t_w;
		r_r <= r_w;
		o_finished_r <= o_finished_w;
		o_result_r <=  o_result_w;
		cnt_r <= cnt_w;
		MP_start_r <= MP_start_w;
		Mont_start_r <= Mont_start_w;
		MP_finish_r <= MP_finish_out;
		MT_finish_r <= MT_finish_out;
		TT_finish_r <= TT_finish_out;
	end

end

endmodule

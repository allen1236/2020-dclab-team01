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
parameter STEP = 256;
parameter BASIS = (257'b1 << 256);
/*========== Output Buffers ==========*/

/*========== Variables ==========*/
logic [255:0]	i_a_r, i_a_w, i_a_in;
logic [255:0]	i_d_r, i_d_w;
logic [255:0]	i_n_r, i_n_w, i_n_in;

logic [1:0]		state_r, state_w;
logic [255:0]	t_r, t_w, t_in, t_out;
logic [255:0]	m_r, m_w, m_in, m_out;
logic [32:0]	cnt_r, cnt_w;
logic [256:0]	y_256;

logic prep_done, m_done, t_done;

logic mont_rst, mont_rst_r, mont_rst_w;
logic mont_start, mont_start_r, mont_start_w;
logic MP_rst, MP_rst_r, MP_rst_w;
logic MP_start, MP_start_r, MP_start_w;

logic [255:0]	o_a_pow_d_r, o_a_pow_d_w;
logic o_finished_r, o_finished_w;

/*========== Output Assignments ==========*/
assign o_finished = o_finished_r;
assign o_a_pow_d = o_a_pow_d_r;
/*========== Compinational Circuits ==========*/
assign m_in = m_r;
assign t_in = t_r;

assign i_n_in = i_n_r;
assign i_a_in = i_a_r;

assign MP_rst = MP_rst_r;
assign mont_rst = mont_rst_r;

assign MP_start = MP_start_r;
assign mont_start = mont_start_r;

ModuloProduct MP1(.i_clk(i_clk), 
				.i_rst(i_rst || MP_rst), 
				.i_start(MP_start), 
				.i_n(i_n_in), 
				.i_a(i_a_in), 
				.i_b(BASIS), 
				.o_result(y_256), /*y under basis 2^256*/
				.o_finish(prep_done)
				);
	
Montgomery m_change(
					.i_clk(i_clk),
					.i_rst(i_rst || mont_rst),
					.i_start(mont_start),
					.i_n(i_n_in),
					.i_a(m_in),
					.i_b(t_in),
					.o_result(m_out),
					.o_finish(m_done)
					);

Montgomery t_trans_256(
					.i_clk(i_clk),
					.i_rst(i_rst || mont_rst),
					.i_start(mont_start),
					.i_n(i_n_in),
					.i_a(t_in), /*t in the slide*/
					.i_b(t_in), /*t in the slide*/
					.o_result(t_out),
					.o_finish(t_done)
					);

always_comb begin

state_w = state_r;
cnt_w = cnt_r;
i_a_w = i_a_r;
i_d_w = i_d_r;
i_n_w = i_n_r;
m_w = m_r;
t_w = t_r;
o_a_pow_d_w = o_a_pow_d_r;
o_finished_w = o_finished_r;
mont_start_w = 0;
mont_rst_w = 1;
MP_start_w = 0;
MP_rst_w = 1;

case(state_r)

S_IDLE:begin
	cnt_w = 0;
	m_w = 1;
	t_w = 0;
	o_finished_w = 0;
	o_a_pow_d_w = 0;
	if (i_start) begin
		state_w = S_PREP;
		i_a_w = i_a;
		i_d_w = i_d;
		i_n_w = i_n;
		MP_start_w = 1;
		MP_rst_w = 0;
	end
end

S_PREP:begin
	if (prep_done) begin
		state_w = S_MONT;
		t_w = y_256;
		m_w = 1;
		mont_start_w = 1;
		mont_rst_w = 0;
		MP_rst_w = 1;
	end

	else begin
		MP_rst_w = 0;
	end
end

S_MONT:begin
	if (m_done && t_done) begin
		case(i_d_r[cnt_r])
			0:begin
				state_w = S_CALC;
				t_w = t_out;
				mont_rst_w = 1;
			end
			1:begin
				state_w = S_CALC;
				t_w = t_out;
				m_w = m_out;
				mont_rst_w = 1;
			end
		endcase
	end

	else begin
		mont_rst_w = 0;
	end
end

S_CALC:begin
	if (cnt_r == 255) begin
		state_w = S_IDLE;
		o_finished_w = 1;
		o_a_pow_d_w = m_r;
		cnt_w = 0;
	end

	else begin
		state_w = S_MONT;
		cnt_w = cnt_r + 1;
		mont_start_w = 1;
		mont_rst_w = 0;
	end

end

endcase

end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin

if(i_rst) begin
	state_r <= S_IDLE;
	cnt_r <= 0;
	m_r <= 1;
	t_r <= 0;
	o_finished_r <= 0;
	o_a_pow_d_r <= 0;
end

else begin
	state_r <= state_w;
	cnt_r <= cnt_w;
	m_r <= m_w;
	t_r <= t_w;
	o_finished_r <= o_finished_w;
	o_a_pow_d_r <= o_a_pow_d_w;
	mont_start_r <= mont_start_w;
	mont_rst_r <= mont_rst_w;
	MP_start_r <= MP_start_w;
	MP_rst_r <= MP_rst_w;
	i_a_r <= i_a_w;
	i_d_r <= i_d_w;
	i_n_r <= i_n_w;

end

end

endmodule

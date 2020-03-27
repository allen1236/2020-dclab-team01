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
/*========== Output Buffers ==========*/

/*========== Variables ==========*/
logic [1:0]		state_r, state_w;
logic [255:0]	m_r, m_w;
logic [16:0]	cnt_r, cnt_w;
logic [255:0]	t_r, t_w;
logic o_finished_r, o_finished_w;
logic [255:0]	o_a_pow_d_r, o_a_pow_d_w;

/*========== Output Assignments ==========*/
assign o_finished = o_finished_r;
assign o_a_pow_d = o_a_pow_d_r;
/*========== Compinational Circuits ==========*/
assign m_in = m_r;
assign t_in = t_r;
assign o_a_pow_d_w = m_r;

always_comb begin

state_w = S_IDLE;
state_r = S_IDLE;
cnt_w = 0;
cnt_r = 0;
m_w = 1;
m_r = 1;
t_w = 0;
t_r = 0;

case(state_r)

S_IDLE:begin
	if (i_start) begin
		state_w = S_PERP;
	end

	else begin
		state_w = S_IDLE;
	end
end

S_PREP:begin
	ModuloProduct MP1(.i_clk(i_clk), 
					.i_rst(i_rst), 
					.i_start(i_start), 
					.i_n(i_n), 
					.i_a(1 << STEP), 
					.i_b(i_a), 
					.o_result(y_256), /*y under basis 2^256*/
					.o_finish(prep_done)
					);
	
	if (prep_done) begin
		state_w = S_MONT;
		t_w = y_256;
	end

	else begin
		state_w = S_PREP;
		t_w = 0;
	end

end

S_MONT:begin
	case(i_d[cnt_r])
		1:begin
			Montgomery m_change(
						.i_clk(i_clk),
						.i_rst(i_rst),
						.i_start(i_start),
						.i_n(i_n),
						.i_a(m_in),
						.i_b(t_in),
						.o_result(m_w),
						.o_finish(m_done)
						);

			if (m_done) begin
				state_w = S_CALC;
			end

			else begin
				state_w = S_MONT;
			end
		
		end
		
		0:begin
			m_w = m_r;
			state_w = S_CALC;
		end

	endcase

end

S_CALC:begin
	Montgomery t_trans_256(
				.i_clk(i_clk),
				.i_rst(i_rst),
				.i_start(i_start),
				.i_n(i_n),
				.i_a(t_in), /*t in the slide*/
				.i_b(t_in), /*t in the slide*/
				.o_result(t_w),
				.o_finish(mt_done)
				);
	if (cnt_r == 255) begin
		state_w = S_IDLE;
		cnt_w = 0;
		m_w = 1;
		o_finished_w = 1;
	end
	
	else if (mt_done) begin
		state_w = S_MONT;
		cnt_w = cnt_r + 1;
		m_w = m_r;
		o_finished_w = 0;
	end

	else begin
		state_w = S_CALC;
		cnt_w = cnt_r;
		m_w = m_r;
		o_finished_w = 0;
	end

end

endcase

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin

if(i_rst == 1) begin
	state_w <= S_IDLE;
	state_r <= S_IDLE;
	cnt_w <= 0;
	cnt_r <= 0;
	m_w <= 1;
	m_r <= 1;
	t_w <= 0;
	t_r <= 0;
	o_finished_w <= 0;
	o_finished_r <= 0;
	o_a_pow_d_w <= 0;
	o_a_pow_d_r <= 0;
end

else begin
	state_r <= state_w;
	cnt_r <= cnt_w;
	m_r <= m_w;
	t_r <= t_w;
	o_finished_r <= o_finished_w;
	o_a_pow_d_r <= o_a_pow_d_w;
end

end

endmodule

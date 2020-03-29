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
parameter basis = (257'b1 << 256);
/*========== Output Buffers ==========*/

/*========== Variables ==========*/
logic [1:0]		state_r, state_w;
logic [255:0]	m_r, m_w, m_in;
logic [32:0]	cnt_r, cnt_w;
logic [255:0]	t_r, t_w, t_in;
logic [256:0]	y_256;
logic [255:0]	o_a_pow_d_r, o_a_pow_d_w;
logic o_finished_r, o_finished_w;
logic prep_done;
logic m_done;
logic mt_done;
logic m_rst, m_rst_reg;
logic t_rst, t_rst_reg;


logic [32:0] bug_r, bug_w;

/*========== Output Assignments ==========*/
assign o_finished = o_finished_r;
assign o_a_pow_d = o_a_pow_d_r;
/*========== Compinational Circuits ==========*/
assign m_in = m_r;
assign t_in = t_r;
assign m_rst = m_rst_reg;
assign t_rst = t_rst_reg;

ModuloProduct MP1(.i_clk(i_clk), 
				.i_rst(i_rst), 
				.i_start(i_start), 
				.i_n(i_n), 
				.i_a(i_a), 
				.i_b(basis), 
				.o_result(y_256), /*y under basis 2^256*/
				.o_finish(prep_done)
				);
	
Montgomery m_change(
					.i_clk(i_clk),
					.i_rst(i_rst || m_rst),
					.i_start(i_start),
					.i_n(i_n),
					.i_a(m_in),
					.i_b(t_in),
					.o_result(m_out),
					.o_finish(m_done)
					);

Montgomery t_trans_256(
					.i_clk(i_clk),
					.i_rst(i_rst || t_rst),
					.i_start(i_start),
					.i_n(i_n),
					.i_a(t_in), /*t in the slide*/
					.i_b(t_in), /*t in the slide*/
					.o_result(t_out),
					.o_finish(mt_done)
					);

always_comb begin
cnt_w = cnt_r;
m_w = m_r;
t_w = t_r;
o_a_pow_d_w = o_a_pow_d_r;
o_finished_w = o_finished_r;

bug_w = bug_r + 1;

m_rst_reg = 1;
t_rst_reg = 1;

case(state_r)

S_IDLE:begin
	if (i_start) begin
		state_w = S_PREP;
		bug_w = 1;
	end

	else begin
		state_w = S_IDLE;
	end
end

S_PREP:begin
	if (prep_done) begin
		state_w = S_MONT;
		t_w = y_256;
		$display("======Modulo Done======");
		$display("%64x",i_a);
		$display("%64x",y_256);
		$display(t_w);
		$display("======================");
		m_w = 1;
	end

	else begin
		state_w = S_PREP;
	end

end

S_MONT:begin

	m_rst_reg = 0;
	t_rst_reg = 0;

	case(i_d[cnt_r])
		1:begin
			if (m_done) begin
				state_w = S_CALC;
				m_w = m_out;
				t_w = t_out;
			end

			else begin
				state_w = S_MONT;
			end
		
		end
		
		0:begin
			state_w = S_CALC;
			t_w = t_out;
		end

	endcase

end

S_CALC:begin

	m_rst_reg = 1;
	t_rst_reg = 1;

	if (cnt_r == 255) begin
		state_w = S_IDLE;
		cnt_w = 0;
		m_w = 1;
		o_finished_w = 1;
		o_a_pow_d_w = m_r;
	end

	else begin
		state_w = S_MONT;
		cnt_w = cnt_r + 1;
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

	bug_r <= bug_w;

	if ((state_r == 0) && (state_w == 1)) begin
		$display("sr = ", state_r);
		$display("sw = ", state_w);
	end

	if ((state_r == 1) && (state_w == 2)) begin
		$display("sr = ", state_r);
		$display("sw = ", state_w);
		$display("tw = ", t_w);
		$display("mw = ", m_w);
		$display("count = ", bug_r);
	end

	else if ((state_r == 2) && (state_w == 3)) begin
		$display("sr = ", state_r);
		$display("sw = ", state_w);
		$display(t_out);
		$display(m_out);
		$display(t_r);
		$display(m_r);
		$display(bug_r);
	end

end

end

endmodule

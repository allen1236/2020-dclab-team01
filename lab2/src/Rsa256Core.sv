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

module Montgomery(
	input			i_clk,
	input			i_rst,
	input			i_start,
	input [256:0]	i_n,
	input [256:0]	i_a,
	input [256:0]	i_b,
	output [256:0]	o_result,
	output			o_finish
);

/*========== States ==========*/
parameter S_IDLE = 2'd0;			// idle (o_finish == 1)
parameter S_LOOP = 2'd1;			// for loop (add b to m according to each bit of a)
parameter S_COMP = 2'd2;			// if m > n, subtract n from m

/*========== Parameters ==========*/

/*========== Variables ==========*/
logic [1:0]		state_r, state_w;
logic			finish_r, finish_w;
logic [7:0]		index_r, index_w;
logic [259:0]	m_r, m_w;

/*========== Output Assignments ==========*/
assign o_result = m_r;
assign o_finish = finish_r;

/*========== Compinational Circuits ==========*/
always_comb begin

	// default values
	state_w		= state_r;
	finish_w	= finish_r;
	index_w		= index_r;
	m_w			= m_r;

	case( state_r )
		S_IDLE: begin
			if ( i_start ) begin
				state_w		= S_LOOP;
				finish_w	= 0;
				index_w		= 0;
				m_w			= 0;
			end
		end
		S_LOOP: begin
			if ( i_a[index_r] ) begin 
				m_w = ( i_b[0] ^ m_r[0] ) ? (m_r + i_b + i_n) >> 1 : (m_r + i_b) >> 1;
			end else begin
				m_w = (  m_r[0] ) ? (m_r + i_n) >> 1 : m_r >> 1;
			end
			//$display("%3d - %64x", index_r, m_w);
			index_w		= index_r + 1;
			state_w		= ( index_r == 8'd255 ) ? S_COMP : state_w;
		end
		S_COMP: begin
			m_w = ( m_r >= i_n ) ? m_r - i_n : m_w;
			state_w  = S_IDLE;
			finish_w = 1'd1;
		end
	endcase
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin
	if ( i_rst  ) begin
		state_r			<= S_IDLE;
		finish_r		<= 0;
		index_r			<= 0;
		m_r				<= 0;
	end
	else begin
		state_r			<= state_w;
		finish_r		<= finish_w;
		index_r			<= index_w;
		m_r				<= m_w;
	end
end

endmodule

module ModuloProduct(
	input			i_clk,
	input			i_rst,
	input			i_start,
	input [255:0]	i_n,
	input [255:0]	i_a,
	input [256:0]	i_b,
	output [256:0]	o_result,
	output			o_finish
);
/*========== States ==========*/
parameter S_IDLE = 0;
parameter S_CALC = 1;
parameter S_MODU = 2;
/*========== Parameters ==========*/
parameter [7:0] K = 8'd255;

/*========== Output Buffers ==========*/
logic[256:0] o_result_w, o_result_r;
logic 		 o_finish_w, o_finish_r;

/*========== Variables ==========*/
logic [1:0] state_w, state_r;
logic [8:0] counter_w, counter_r;
logic [257:0] mult_w, mult_r;
logic [256:0] i_a_w, i_a_r;
logic [256:0] i_n_w, i_n_r;

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
	i_a_w      = i_a_r;
	i_n_w      = i_n_r;

	case(state_r)

	S_IDLE: begin
		counter_w = 8'd0;
		if(i_start) begin
			state_w = S_MODU;
			i_a_w = i_a;
			i_n_w = i_n;
			mult_w = i_b;
			o_result_w = 1'd0;
		end
	end

	S_MODU: begin
		if ( mult_r > i_n_r ) begin
			mult_w = mult_r - i_n_r;
		end else begin
			state_w = S_CALC;
		end
	end

	S_CALC: begin
		counter_w = counter_r + 1;
		if( counter_r > K) begin
			state_w = S_IDLE;
			o_finish_w = 1'd1;
		end
		else begin
			if( i_a_r[counter_r]==1 ) begin
				o_result_w = ( (o_result_r+mult_r) >= i_n_r) ? o_result_r+mult_r-i_n_r : o_result_r+mult_r;
			end
		end
		mult_w = (mult_r+mult_r > i_n_r) ? ((mult_r+mult_r)-i_n_r) : mult_r<<1;
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
		i_a_r      <= 0;
		i_n_r      <= 0;
	end
	else begin
		counter_r  <= counter_w;
		state_r    <= state_w;
		mult_r     <= mult_w;
		o_result_r <= o_result_w;
		o_finish_r <= o_finish_w;
		i_a_r      <= i_a_w;
		i_n_r      <= i_n_w;
	end
end

endmodule

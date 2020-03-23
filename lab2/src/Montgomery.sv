module Montgomery{
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
parameter S_IDLE = 2'd0;
parameter S_CALC = 2'd1;
parameter S_MINU = 2'd1;

/*========== Parameters ==========*/

/*========== Variables ==========*/
logic [1:0]		state_r, state_w;
logic			finish_r, finish_w;
logic [7:0]		index_r, index_w;
logic [255:0]	m_r, m_w;

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

	case( state_r ):
		S_IDLE: begin
			if ( i_start ) begin
				state_w		= S_CALC;
				finish_w	= 0;
				index_w		= 0;
				m_w			= 0;
			end
		end
		S_CALC: begin
			if ( i_a[index_r] ) begin 
				m_w = ( i_b[0] ^ m_r[0] ) ? (m_r + i_b + N) >> 1 : (m_r + i_b) >> 1;
			end
			index_w		= index_r + 1;
			state_w		= ( index_r == 8'd255 ) ? S_MINU : state_w;
		end
		S_MINU: begin
			m_w = ( m_r > i_n )  ? m_r - i_n : m_w;
			state_w  = S_IDLE;
			finsi_w = 1'd1;
		end
	endcase
end

/*========== Sequential Circuits ==========*/
always_ff @(posedge i_clk or posedge i_rst) begin
	if ( i_rst  ) begin
		state_r			<= S_IDLE;
		finish_r		<= 1;
		index_r			<= 0;
		m_r				<= 0;
	end
	else
		state_r			<= state_w;
		finish_r		<= finish_w;
		index_r			<= index_w;
		m_r				<= m_w;
	end
end

endmodule

module Top (
	input        i_clk,
	input        i_start,
	input        i_rst_n,
	input		 i_prev ,
	input		 i_next ,
	output [3:0] o_random_out
);

// ===== States =====
parameter S_IDLE = 1'd0;
parameter S_RAND = 1'd1;

// ===== Constants =====
parameter SEED_B = 4'd9;
parameter INDEX_LEN = 8'd23;		// MAX
parameter INDEX_MAX = 8'd31;		// MAX(23) + 8
parameter INDEX_MIN = 8'd26;		// MIN(18) + 8
parameter CLK_UNIT= 48'd64;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;

// ==== Registers & Wires =====
logic state_r, state_w;
logic [47:0] counter_r, counter_w;
logic [7:0] seed_r, seed_w;
logic [7:0] index_r, index_w;
logic [3:0] mem_r[3:0], mem_w[3:0];

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;
initial o_random_out_r = 4'd0;
initial mem_r = 28'd0;

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w	= o_random_out_r;
	counter_w 		= counter_r + CLK_UNIT;
	seed_w			= seed_r;
	index_w			= INDEX_MIN;
	state_w			= state_r;
	mem_w[0]		= mem_r[0];
	mem_w[1]		= mem_r[1];
	mem_w[2]		= mem_r[2];
	mem_w[3]		= mem_r[3];

	case(state_r)

	S_IDLE: begin
		if (i_start) begin
			counter_w	= 48'd0;
			seed_w 		= counter_r[INDEX_MAX:INDEX_MAX-7] * 2 + 16'd1;
			state_w		= S_RAND;
		end
	end

	S_RAND: begin
		o_random_out_w	= (counter_r[index_r -: INDEX_LEN] == 0) ? (o_random_out_r * seed_r + SEED_B): o_random_out_w;
		counter_w		= counter_r[INDEX_MAX] ? CLK_UNIT: counter_w;
		index_w			= counter_r[INDEX_MAX] ? index_r + 1: index_r;
		state_w			= ( index_r == (INDEX_MAX-1) || i_start ) ? S_IDLE : state_w;
		mem_w[0] 			= ( index_r == (INDEX_MAX-1) || i_start ) ? o_random_out_r : mem_w;
	end

	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	o_random_out_r	<= o_random_out_w;
	mem_r 			<= mem_w;

	if (!i_rst_n) begin
		seed_r			<= 4'd0;
		counter_r		<= 48'd0;
		index_r 		<= 8'd0;
		state_r			<= S_IDLE;
	end
	else begin
		seed_r			<= seed_w;
		counter_r		<= counter_w;
		index_r			<= index_w;
		state_r			<= state_w;
	end
end

endmodule

module Top (
	input        i_clk,
	input        i_start,
	input        i_rst_n,
	input		 i_prev ,
	input		 i_next ,
	output [3:0] o_random_out1,
	output [3:0] o_random_out2,
	output [3:0] o_random_out3,
	output [3:0] o_random_out4
	
);

// ===== States =====
parameter S_IDLE = 1'd0;
parameter S_RAND = 1'd1;

// ===== Constants =====
parameter SEED_B = 1;
parameter SEED_A = 22695477;
parameter INDEX_LEN = 8'd23;		// MAX
parameter INDEX_MAX = 8'd31;		// MAX(23) + 8
parameter INDEX_MIN = 8'd27;		// MIN(18) + 8
parameter CLK_UNIT= 48'd64;

// ===== Output Buffers =====
// ==== Registers & Wires =====
logic state_r, state_w;
logic [47:0] counter_r, counter_w;
logic [7:0] seed_r, seed_w;
logic [7:0] index_r, index_w;
logic [3:0] mem_r[3:0], mem_w[3:0];

// ===== Output Assignments =====
initial mem_r[0] = 1;
initial mem_r[1] = 1;
initial mem_r[2] = 1;
initial mem_r[3] = 1;
assign o_random_out1 = mem_r[0];
assign o_random_out2 = mem_r[1];
assign o_random_out3 = mem_r[2];
assign o_random_out4 = mem_r[3];


// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	counter_w 		= counter_r + CLK_UNIT;
	seed_w			= seed_r;
	index_w			= INDEX_MIN;
	state_w			= state_r;
	mem_w[3]		= mem_r[3];
	mem_w[2]		= mem_r[2];
	mem_w[1]		= mem_r[1];
	mem_w[0]		= mem_r[0];

	case(state_r)

	S_IDLE: begin
		if (i_start) begin
			counter_w	= 48'd0;
			mem_w[0] 	= counter_r[12:9];
			state_w		= S_RAND;
			mem_w[3]		= mem_r[2];
			mem_w[2]		= mem_r[1];
			mem_w[1]		= mem_r[0];
		end
	end

	S_RAND: begin

		mem_w[0]		= (counter_r[index_r -: INDEX_LEN] == 0) ? (mem_r[0] * SEED_A + SEED_B): mem_w[0];
		counter_w		= counter_r[INDEX_MAX] ? CLK_UNIT: counter_w;
		index_w			= counter_r[INDEX_MAX] ? index_r + 1: index_r;
		state_w 		= ( index_r == (INDEX_MAX-1) || i_start ) ? S_IDLE : state_w;
	end

	endcase

end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	
	
	// reset
	if (!i_rst_n) begin
		mem_r[3] 		<= 0;
		mem_r[2] 		<= 0;
		mem_r[1] 		<= 0;
		mem_r[0]  		<= 0;
		seed_r			<= 4'd0;
		counter_r		<= 48'd0;
		index_r 		<= 8'd0;
		state_r			<= S_IDLE;
	end
	else begin
		mem_r[3] 		<= mem_w[3];
		mem_r[2] 		<= mem_w[2];
		mem_r[1] 		<= mem_w[1];
		mem_r[0]		<= mem_w[0];
		seed_r			<= seed_w;
		counter_r		<= counter_w;
		index_r			<= index_w;
		state_r			<= state_w;
	end
end

endmodule

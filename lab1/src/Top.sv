module Top (
	input        i_clk,
	input        i_start,
	input        i_rst_n,
	input		 i_prev,
	input		 i_next,
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
//parameter INDEX_LEN = 8'd23;		// MAX
//parameter INDEX_MAX = 8'd31;		// MAX(23) + 8
//parameter INDEX_MIN = 8'd27;		// MIN(19) + 8
parameter INDEX_LEN = 8'd11;		// MAX
parameter INDEX_MAX = 8'd19;		// MAX(23) + 8
parameter INDEX_MIN = 8'd15;		// MIN(19) + 8
// clk unit havs better implementation
parameter CLK_UNIT= 48'd64;
parameter MEM_MAX = 63;

// ===== Output Buffers =====
logic [15:0] out_r, out_w;

// ==== Registers & Wires =====
logic state_r, state_w;
logic [47:0] counter_r, counter_w;
logic [7:0] seed_r, seed_w;
logic [7:0] index_r, index_w;
logic [MEM_MAX:0] mem_r, mem_w;
logic [8:0] ptr_r, ptr_w;

// ===== initialize =====

// ===== Output Assignments =====
assign o_random_out1 = out_r[3:0];
assign o_random_out2 = out_r[7:4];
assign o_random_out3 = out_r[11:8];
assign o_random_out4 = out_r[15:12];


// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	counter_w 		= counter_r + CLK_UNIT;
	seed_w			= seed_r;
	index_w			= INDEX_MIN;
	state_w			= state_r;
	mem_w			= mem_r;
	ptr_w			= ptr_r;
	out_w			= mem_r[ptr_r -: 16];

	case(state_r)

	S_IDLE: begin
		if (i_start) begin
			counter_w			= 48'd0;
			mem_w[3:0]			= counter_r[12:9];
			state_w				= S_RAND;
			mem_w[MEM_MAX:4]	= mem_r[MEM_MAX-4:0];
			ptr_w				= 15;
		end
		else if (i_prev) begin
			ptr_w = (ptr_r < MEM_MAX) ? ptr_r+4 : ptr_w;
		end
		else if (i_next) begin
			ptr_w = (ptr_r > 15) ? ptr_r-4 : ptr_w;
			
		end
	end

	S_RAND: begin
		mem_w[3:0]		= (counter_r[index_r -: INDEX_LEN] == 0) ? (mem_r[3:0] * SEED_A + SEED_B): mem_w[3:0];
		counter_w		= counter_r[INDEX_MAX] ? CLK_UNIT: counter_w;
		index_w			= counter_r[INDEX_MAX] ? index_r + 1: index_r;
		state_w 		= (index_r == (INDEX_MAX-1) || i_start) ? S_IDLE : state_w;
	end

	endcase

end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	
	// reset
	if (!i_rst_n) begin
		out_r			<= 0;
		ptr_r			<= 15;
		mem_r			<= 0;
		seed_r			<= 4'd0;
		counter_r		<= 48'd0;
		index_r 		<= 8'd0;
		state_r			<= S_IDLE;
	end
	else begin
		out_r			<= out_w;
		ptr_r			<= ptr_w;
		mem_r			<= mem_w;
		seed_r			<= seed_w;
		counter_r		<= counter_w;
		index_r			<= index_w;
		state_r			<= state_w;
	end
end

endmodule

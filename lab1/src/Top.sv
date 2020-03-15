module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	input 	     i_prev ,
	output [3:0] o_random_out
);

// please check out the working example in lab1 README (or Top_exmaple.sv) first

// states
parameter S_IDLE = 0;
parameter S_RUN  = 1;

//random Number buffer
logic[3:0] random_o_w, random_o_r;

//wire & register
logic state_w, state_r;

//counter
logic[31:0] counter_w, counter_r;

assign o_random_out = random_o_r;

always_ff @ (posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		counter_r <= 0;
		random_o_r <= 0;
		state_r <= S_IDLE;
	end
	else begin
		random_o_r <= random_o_w;
		counter_r <= counter_w;
		state_r <= state_w;
	end
end

always_comb begin
	random_o_w = random_o_r;
	state_w = state_r;
	counter_w = counter_r+1;
	
	case(state_r) begin
		S_RUN: begin

		end

		S_IDLE: begin

		end
	endcase
end

endmodule

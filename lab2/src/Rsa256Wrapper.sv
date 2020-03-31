module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_RX_QUERY = 3'd0;
localparam S_READ = 3'd1;
localparam S_TX_QUERY = 3'd2;
localparam S_WRITE = 3'd3;
localparam S_CALC = 3'd4;
localparam S_READ_BUFF = 3'd5;

logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [1:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic avm_address_out, avm_read_out, avm_write_out;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

assign avm_address = avm_address_out;
assign avm_read = avm_read_out;
assign avm_write = avm_write_out;
assign avm_writedata = dec_r[247-:8];

//===== Submudules ======

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);


always_comb begin
    n_w = n_r;
    d_w = d_r;
    enc_w = enc_r;
    dec_w = dec_r;
    state_w = state_r;

    bytes_counter_w = bytes_counter_r;

    rsa_start_w = 0;

    case (state_r) 
        S_RX_QUERY: begin
            avm_address_out = STATUS_BASE;
            avm_read_out = 1;
            avm_write_out = 0;
        end
        S_READ: begin
            avm_address_out = RX_BASE;
            avm_read_out = 1;
            avm_write_out = 0;
        end
        S_READ_BUFF: begin
            avm_address_out = RX_BASE;
            avm_read_out = 0;
            avm_write_out = 0;
        end
        S_TX_QUERY: begin
            avm_address_out = STATUS_BASE;
            avm_read_out = 1;
            avm_write_out = 0;
        end
        S_WRITE: begin
            avm_address_out = TX_BASE;
            avm_read_out = 0;
            avm_write_out = 1;
        end
        S_CALC: begin
            avm_address_out = STATUS_BASE;
            avm_read_out = 0;
            avm_write_out = 0;
        end
    endcase

    if ( !avm_waitrequest ) begin
        case ( state_r )
            S_RX_QUERY: begin
                if ( avm_readdata[RX_OK_BIT] ) begin
                    state_w = S_READ;
                end
            end
            S_READ: begin
                case ( bytes_counter_r[6:5] ) 
                    2: begin	// 95 ~ 64: read n
						n_w = ( n_r << 8 ) + avm_readdata[7:0];
                    end
                    1: begin	// 63 ~ 32: read key
						d_w = ( d_r << 8 ) + avm_readdata[7:0];
                    end
                    default: begin	// 31 ~ 0: read data
						enc_w = ( enc_r << 8 ) + avm_readdata[7:0];
                    end
				endcase
				if ( bytes_counter_r == 0 ) begin	// finish reading data
					state_w = S_CALC;
					rsa_start_w = 1;
					$display("start calc");
				end else begin						// keep reading
					state_w = S_READ_BUFF;
					bytes_counter_w = bytes_counter_r - 1;
				end
            end
            S_READ_BUFF: begin
                state_w = S_RX_QUERY;
            end
            S_CALC: begin
				rsa_start_w = 0;
				if ( rsa_finished ) begin
					dec_w = rsa_dec;
					state_w = S_TX_QUERY;
					bytes_counter_w = 7'd30;
					$display("calc done");
				end
            end
            S_TX_QUERY: begin
                if ( avm_readdata[TX_OK_BIT] ) begin
                    state_w = S_WRITE;
                end
            end
            S_WRITE: begin	// finish writing the left most byte, shift and change state
				dec_w = dec_r << 8;
				state_w = ( bytes_counter_r == 0 ) ? S_RX_QUERY : S_TX_QUERY;
				bytes_counter_w = ( bytes_counter_r == 0 ) ? 7'd95 : bytes_counter_r - 1;
				if ( bytes_counter_r == 0 ) begin $display("finish"); end
            end
        endcase
    end
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        state_r <= S_RX_QUERY;
        bytes_counter_r <= 7'd95;
        rsa_start_r <= 0;
    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
    end
end

endmodule
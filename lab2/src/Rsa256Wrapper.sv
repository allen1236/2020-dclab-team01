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
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
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
    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;
    state_w = state_r;
    bytes_counter_w = bytes_counter_r;
    rsa_start_w = rsa_start_r;

    case (state_r) begin
        S_RX_QUERY: begin
            avm_address = STATUS_BASE;
            avm_read = 1;
            avm_write = 0;
        end
        S_READ: begin
            avm_address = RX_BASE;
            avm_read = 1;
            avm_write = 0;
        end
        S_READ_BUFF: begin
            avm_address = RX_BASE;
            avm_read = 0
            avm_write = 0
        end
        S_TX_QUERY: begin
            avm_address = STATUS_BASE;
            avm_read = 1;
            avm_write = 0
        end
        S_WRITE: begin
            avm_address = TX_BASE;
            avm_read = 0
            avm_write = 1;
        end
        S_CALC: begin
            avm_address_w = STATUS_BASE;
            avm_read_w = 0
            avm_write_w = 0;
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
            end
            S_READ_BUFF: begin
                state_w = S_RX_QUERY;
            end
            S_TX_QUERY: begin
                if ( avm_readdata[TX_OK_BIT] ) begin
                    state_w = S_WRITE;
                end
            end
            S_WRITE: begin
            end
            S_CALC: begin
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
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_GET_KEY;
        bytes_counter_r <= 63;
        rsa_start_r <= 0;
    end else begin
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
    end
end

endmodule
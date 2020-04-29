`timescale 1ns/100ps

module I2cInitializer(
    input  i_rst_n,
    input  i_clk,
    input  i_start,
    output o_finished, //
    output o_sclk,    
    output o_sdat,    
    output o_oen      // for every 8-bit data sent
);


localparam [23:0] config_data[6:0] = {
    24'b0011_0100_000_1111_0_0000_0000,
    24'b0011_0100_000_0100_0_0001_0101,
    24'b0011_0100_000_0101_0_0000_0000,
    24'b0011_0100_000_0110_0_0000_0000,
    24'b0011_0100_000_0111_0_0100_0010,
    24'b0011_0100_000_1000_0_0001_1001,
    24'b0011_0100_000_1001_0_0000_0001
} ;

/* satates */
localparam S_IDLE = 3'd0;
localparam S_TX   = 3'd1;

logic o_sclk_r, o_sclk_w;
logic o_sdat_r, o_sdat_w;
logic[3:0] state_r, state_w;
logic o_finished_r, o_finished_w;
logic[5:0] bit_cnt_r, bit_cnt_w;
logic[3:0] conf_cnt_r, conf_cnt_w;
logic ack_r, ack_w;

/* ouput assignments */
assign o_finished = o_finished_r;
assign o_oen = ~ack_r;
assign o_sclk = o_sclk_r;
assign o_sdat = o_sdat_r;


/* combinational */
always_comb begin
    state_w  = state_r;
    o_sclk_w = o_sclk_r;
    o_sdat_w = o_sdat_r;
    o_finished_w = o_finished_r;
    conf_cnt_w = conf_cnt_r;
    bit_cnt_w = bit_cnt_r;
    ack_w = ack_r;

    case(state_r)
        S_IDLE: begin
            if(o_sclk_r && !o_sdat_r) begin
                o_finished_w = 1'd1;
            end else begin
                o_finished_w = 1'd0;
            end
            o_sclk_w = 1'd1;
            o_sdat_w = 1'd1;
            if(i_start) begin
                state_w = S_TX;
                o_sdat_w = 0;
            end
        end
        S_TX : begin
            o_sclk_w = ~o_sclk_r;
            if(o_sclk_r) begin // negedge of sclk
                if( !ack_r && bit_cnt_r%8==0 && bit_cnt_r!=0) begin // ack for every 8 bits
                    bit_cnt_w = (bit_cnt_r==24) ? 0 : bit_cnt_r;
                    conf_cnt_w = (bit_cnt_r==24) ? (conf_cnt_r+1) : conf_cnt_r;
                    o_sdat_w = 1'bz;
                    ack_w = 1'd1;
                end
                else begin // read bit
                    ack_w = 1'd0;
                    o_sdat_w = config_data[ conf_cnt_r ][ 23-bit_cnt_r ];
                    bit_cnt_w = bit_cnt_r+1;
                end
            end
            else if( conf_cnt_w > 6) begin // finished 24*7 bits setting
                state_w = S_IDLE;
                o_sclk_w = 1'd1;
                o_sdat_w = 1'd0;
                o_finished_w = 1'd1;
            end
        end
    endcase
end

/* sequential */
always_ff @ (posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state_r = S_IDLE;
        o_finished_r = 0;
        o_sclk_r = 1;
        o_sdat_r = 1;
        bit_cnt_r = 0;
        conf_cnt_r = 0;
        ack_r = 0;
    end
    else begin
        state_r = state_w;
        o_finished_r = o_finished_w;
        o_sclk_r = o_sclk_w;
        o_sdat_r = o_sdat_w;
        bit_cnt_r = bit_cnt_w;
        conf_cnt_r = conf_cnt_w;
        ack_r = ack_w;
    end

end
endmodule
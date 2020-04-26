module I2cInitializer(
    input  i_rst_n,
    input  i_clk,
    input  i_start,
    output o_finished, //
    output o_sclk,    
    output o_sdat,    
    output o_oen,      // for every 8-bit data sent
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


endmodule
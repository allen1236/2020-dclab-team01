module SevenHexDecoder (
	input        [4:0] i_hex,
	output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1011000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;
always_comb begin
	case(i_hex)
		5'h0: begin o_seven_ten = D0; o_seven_one = D0; end
		5'h1: begin o_seven_ten = D0; o_seven_one = D1; end
		5'h2: begin o_seven_ten = D0; o_seven_one = D2; end
		5'h3: begin o_seven_ten = D0; o_seven_one = D3; end
		5'h4: begin o_seven_ten = D0; o_seven_one = D4; end
		5'h5: begin o_seven_ten = D0; o_seven_one = D5; end
		5'h6: begin o_seven_ten = D0; o_seven_one = D6; end
		5'h7: begin o_seven_ten = D0; o_seven_one = D7; end
		5'h8: begin o_seven_ten = D0; o_seven_one = D8; end
		5'h9: begin o_seven_ten = D0; o_seven_one = D9; end
		5'ha: begin o_seven_ten = D1; o_seven_one = D0; end
		5'hb: begin o_seven_ten = D1; o_seven_one = D1; end
		5'hc: begin o_seven_ten = D1; o_seven_one = D2; end
		5'hd: begin o_seven_ten = D1; o_seven_one = D3; end
		5'he: begin o_seven_ten = D1; o_seven_one = D4; end
		5'hf: begin o_seven_ten = D1; o_seven_one = D5; end
		5'h10: begin o_seven_ten = D1; o_seven_one = D6; end
		5'h11: begin o_seven_ten = D1; o_seven_one = D7; end
		5'h12: begin o_seven_ten = D1; o_seven_one = D8; end
		5'h13: begin o_seven_ten = D1; o_seven_one = D9; end
		5'h14: begin o_seven_ten = D2; o_seven_one = D0; end
		5'h15: begin o_seven_ten = D2; o_seven_one = D1; end
		5'h16: begin o_seven_ten = D2; o_seven_one = D2; end
		5'h17: begin o_seven_ten = D2; o_seven_one = D3; end
		5'h18: begin o_seven_ten = D2; o_seven_one = D4; end
		5'h19: begin o_seven_ten = D2; o_seven_one = D5; end
		5'h1a: begin o_seven_ten = D2; o_seven_one = D6; end
		5'h1b: begin o_seven_ten = D2; o_seven_one = D7; end
		5'h1c: begin o_seven_ten = D2; o_seven_one = D8; end
		5'h1d: begin o_seven_ten = D2; o_seven_one = D9; end
		5'h1e: begin o_seven_ten = D3; o_seven_one = D0; end
		5'h1f: begin o_seven_ten = D3; o_seven_one = D1; end
	endcase
end

endmodule

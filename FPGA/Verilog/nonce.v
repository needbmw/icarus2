`timescale 1ns / 1ps

module nonce(clk, nonce, true_nonce);
	input clk;
   input [31:0] nonce;
	output [31:0] true_nonce;

	reg[31:0] cnt;

	wire [31:0] rev_nonce;
	wire [31:0] new_nonce;
//	assign rev_nonce = {nonce[7:0], nonce[15:8], nonce[23:16], nonce[31:24] };
	assign rev_nonce = { nonce[0], nonce[1], nonce[2], nonce[3], nonce[4], nonce[5], nonce[6], nonce[7],
								nonce[8], nonce[9], nonce[10], nonce[11], nonce[12], nonce[13], nonce[14], nonce[15],
								nonce[16], nonce[17], nonce[18], nonce[19], nonce[20], nonce[21], nonce[22], nonce[23],
								nonce[24], nonce[25], nonce[26], nonce[27], nonce[28], nonce[29], nonce[30], nonce[31]
								};
	assign new_nonce = rev_nonce - 32'hc0;
/*	assign true_nonce = { new_nonce[0], new_nonce[1], new_nonce[2], new_nonce[3], new_nonce[4], new_nonce[5], new_nonce[6], new_nonce[7],
								new_nonce[8], new_nonce[9], new_nonce[10], new_nonce[11], new_nonce[12], new_nonce[13], new_nonce[14], new_nonce[15],
								new_nonce[16], new_nonce[17], new_nonce[18], new_nonce[19], new_nonce[20], new_nonce[21], new_nonce[22], new_nonce[23],
								new_nonce[24], new_nonce[25], new_nonce[26], new_nonce[27], new_nonce[28], new_nonce[29], new_nonce[30], new_nonce[31]
								}; */
	assign true_nonce = new_nonce;
	
	
	
endmodule

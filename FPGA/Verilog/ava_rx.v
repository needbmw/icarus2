`timescale 1ns / 1ps



module ava_rx(
	input clk,
	input rx_p,
	input rx_m,
	input en,
	output [(NONCE_SIZE-1):0] data,
	input global_reset,
	output reg ready
);

	parameter NONCE_SIZE = 32;

	reg [(NONCE_SIZE-1):0] buffer;
	assign data = buffer[(NONCE_SIZE-1):0];
	
	reg en_prev;
	reg[9:0] bitcnt_p;
	reg[9:0] bitcnt_m;
	reg[9:0] bitcnt;

	reg rx_p_trig;
	reg rx_m_trig;

	reg bitval;

	reg[4:0] rx_m_prev;
	reg[4:0] rx_p_prev;
	
	wire rx_m_posedge;
	
/*	assign bad_m = (rx_m_prev[3:0] == 4'b1010) || (rx_m_prev[3:0] == 4'b1011) ||
						(rx_m_prev[3:0] == 4'b0110) || (rx_m_prev[3:0] == 4'b0101) ||
						(rx_m_prev[3:0] == 4'b1001) || (rx_m_prev[3:0] == 4'b1101);
						
	assign bad_p = (rx_p_prev[3:0] == 4'b1010) || (rx_p_prev[3:0] == 4'b1011) ||
						(rx_p_prev[3:0] == 4'b0110) || (rx_p_prev[3:0] == 4'b0101) ||
						(rx_p_prev[3:0] == 4'b1001) || (rx_p_prev[3:0] == 4'b1101);
*/	
	assign rx_m_posedge = (rx_m_prev[4:0] == 5'b00111);
//	assign rx_m_posedge = (rx_m_prev[7:0] == 8'b00011111);

	wire rx_m_no_posedge;
	assign rx_m_no_posedge = ((rx_m_prev[4:0] == 5'b00000));
//	assign rx_m_no_posedge = ((rx_m_prev[7:0] == 8'b00000000));
	
	wire rx_p_posedge;
	assign rx_p_posedge = (rx_p_prev[4:0] == 5'b00111);
//	assign rx_p_posedge = (rx_p_prev[7:0] == 8'b00011111);

	wire rx_p_no_posedge;
	assign rx_p_no_posedge = (rx_p_prev[4:0] == 5'b00000);
//	assign rx_p_no_posedge = (rx_p_prev[7:0] == 8'b00000000);
	
	always @(posedge clk)
	begin
	
		en_prev <= en;
	
		rx_p_prev <= (rx_p_prev << 1);
		rx_m_prev <= (rx_m_prev << 1);
		rx_p_prev[0] <= rx_p;
		rx_m_prev[0] <= rx_m;		

		if(ready || global_reset || (en && !en_prev) || ((rx_p == 1'b1 && rx_m == 1'b1)))
		begin
			ready <= 1'b0;
			bitcnt <= 10'd0;
		end
		else if(rx_p_posedge && rx_m_no_posedge && en)
		begin
			buffer <= (buffer << 1);
			buffer[0] <= 1;
			bitcnt <= bitcnt+1;
		end
		else if(rx_p_no_posedge && rx_m_posedge && en)
		begin
			buffer <= (buffer << 1);
			buffer[0] <= 0;
			bitcnt <= bitcnt+1;
		end

		if(bitcnt == NONCE_SIZE)
		begin
			ready <= 1'b1;
		end
	end

endmodule


module ava_tx(
	input clk,
	input start,
	input global_reset,
	input [575:0] data,
	input [7:0] pll0,
	input [7:0] pll1,
	input [7:0] mode,
	output reg busy,
	output reg tx_p0,
	output reg tx_m0,
	output reg tx_p1,
	output reg tx_m1
    );

//parameter ClkFrequency = 32000000; // 32MHz
//parameter Baud = 500000;

/*	parameter N0 = 32'h0;
	parameter N1 = 32'h19999999;
	parameter N2 = 32'h33333332;
	parameter N3 = 32'h4ccccccb;
	parameter N4 = 32'h66666664;
	parameter N5 = 32'h7ffffffd;
	parameter N6 = 32'h99999996;
	parameter N7 = 32'hb333332f;
	parameter N8 = 32'hccccccc8;
	parameter N9 = 32'he6666661; */
	
	/*parameter N9 = 32'h0;
	parameter N8 = 32'h19999999;
	parameter N7 = 32'h33333332;
	parameter N6 = 32'h4ccccccb;
	parameter N5 = 32'h66666664;
	parameter N4 = 32'h7ffffffd;
	parameter N3 = 32'h99999996;
	parameter N2 = 32'hb333332f;
	parameter N1 = 32'hccccccc8;
	parameter N0 = 32'he6666661; 

	parameter N19 = 32'h0;
	parameter N18 = 32'h19999999;
	parameter N17 = 32'h33333332;
	parameter N16 = 32'h4ccccccb;
	parameter N15 = 32'h66666664;
	parameter N14 = 32'h7ffffffd;
	parameter N13 = 32'h99999996;
	parameter N12 = 32'hb333332f;
	parameter N11 = 32'hccccccc8;
	parameter N10 = 32'he6666661; */

	

	parameter N9 = 32'd0;
	parameter N8 = 32'd214748465;
	parameter N7 = 32'd429496729;
	parameter N6 = 32'd644245094;
	parameter N5 = 32'd858993459;
	parameter N4 = 32'd1073741824;
	parameter N3 = 32'd1288490188;
	parameter N2 = 32'd1503238553;
	parameter N1 = 32'd1717986918;
	parameter N0 = 32'd1932735283;

	parameter N19 = 32'd2147483648;
	parameter N18 = 32'd2362232012;
	parameter N17 = 32'd2576980377;
	parameter N16 = 32'd2791728742;
	parameter N15 = 32'd3006477107;
	parameter N14 = 32'd3221225472;
	parameter N13 = 32'd3435973836;
	parameter N12 = 32'd3650722201;
	parameter N11 = 32'd3865470566;
	parameter N10 = 32'd4080218931;




/*	parameter N0 = 32'd0;
	parameter N1 = 32'd0500000000;
	parameter N2 = 32'd1000000000;
	parameter N3 = 32'd1500000000;
	parameter N4 = 32'd2000000000;
	parameter N5 = 32'd2500000000;
	parameter N6 = 32'd3000000000;
	parameter N7 = 32'd3500000000;
	parameter N8 = 32'd4000000000;
	parameter N9 = 32'd0000000000;
	parameter N10 = 32'd2000000000;
	parameter N11 = 32'd3000000000;
	parameter N12 = 32'd0000000000;
	parameter N13 = 32'd1000000000;
	parameter N14 = 32'd2000000000;
	parameter N15 = 32'd3000000000;
	parameter N16 = 32'd0;
	parameter N17 = 32'd1000000000;
	parameter N18 = 32'd2000000000;
	parameter N19 = 32'd3000000000;
*/	
	reg[607:0] tx_data;
	reg[319:0] tx_nonce0;
	reg[319:0] tx_nonce1;
	
	reg [4:0] baud_cnt;
	reg [9:0] bit_cnt;
	reg reset_cycle;

	always @(posedge clk)
	begin
		
		if(global_reset)
		begin
			tx_p0 <= 1;
			tx_m0 <= 1;
			tx_p1 <= 1;
			tx_m1 <= 1;
			baud_cnt <= 0;
			bit_cnt <= 0;
			busy <= 0;
		end
		
		if(start && !busy)
		begin
			tx_data[607:0] <=  { data[575:0] , pll1[7:0], pll0[7:0], 8'd0, mode[7:0] };
			tx_nonce0[319:0] <= { N9, N8, N7, N6, N5, N4, N3, N2, N1, N0 };
			tx_nonce1[319:0] <= { N19, N18, N17, N16, N15, N14, N13, N12, N11, N10 };
			busy <= 1;
			bit_cnt <= 10'd0;
			reset_cycle <= 1;
			baud_cnt <= 5'd1;
		end
	
		if(busy)
		begin
			baud_cnt <= baud_cnt + 7'd1;
			if(reset_cycle)
			begin
				tx_p0 <= 1'b0;
				tx_m0 <= 1'b0;
				tx_p1 <= 1'b0;
				tx_m1 <= 1'b0;
				if(baud_cnt == 5'b0)
					reset_cycle <= 0;
			end
			else
			begin
				if(baud_cnt == 5'd0)
				begin
					if(bit_cnt == 10'd927)
							busy <= 0;
					else
						bit_cnt <= bit_cnt + 8'd1;
						if(bit_cnt < 10'd608)
						begin
							tx_data[606:0] <= tx_data[607:1]; // shift right data register
						end
						else
						begin
							tx_nonce0 <= (tx_nonce0 >> 1);
							tx_nonce1 <= (tx_nonce1 >> 1);
						end
				end
				else
					begin
					if(!(baud_cnt[4:0] & 5'b10000)) // passive half
					begin
						tx_p0 <= 1'b0;
						tx_m0 <= 1'b0;
						tx_p1 <= 1'b0;
						tx_m1 <= 1'b0;
					end
					else // active half
					begin
						if(bit_cnt < 10'd608)
						begin
							if(tx_data[0])
							begin
								tx_p0 <= 1'b1;
								tx_m0 <= 1'b0;
								tx_p1 <= 1'b1;
								tx_m1 <= 1'b0;
							end
							else
							begin
								tx_p0 <= 1'b0;
								tx_m0 <= 1'b1;
								tx_p1 <= 1'b0;
								tx_m1 <= 1'b1;
							end
						end
						else
						begin
							if(tx_nonce0[0])
							begin
								tx_p0 <= 1'b1;
								tx_m0 <= 1'b0;
							end
							else
							begin
								tx_p0 <= 1'b0;
								tx_m0 <= 1'b1;
							end
							if(tx_nonce1[0])
							begin
								tx_p1 <= 1'b1;
								tx_m1 <= 1'b0;
							end
							else
							begin
								tx_p1 <= 1'b0;
								tx_m1 <= 1'b1;
							end
						end
					end
					end
			end
		end
		else
		begin
			tx_p0 <= 1'b1;
			tx_m0 <= 1'b1;
			tx_p1 <= 1'b1;
			tx_m1 <= 1'b1;
		end
	end

endmodule

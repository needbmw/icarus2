`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:14:40 04/04/2013 
// Design Name: 
// Module Name:    raggedstone2_led 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module heartbeat(input clk, output led_clk, output led);

	reg [19:0] cnt;
	reg [7:0] cnt2;

	reg led_reg;
	assign led = led_reg;
	
	reg led_clk_reg;
	assign led_clk = led_clk_reg;

	always @(posedge clk)
	begin
		if (cnt == 20'h1e848)
		begin
			cnt <= 20'd0;
			led_clk_reg <= ~led_clk_reg;
			if (cnt2 == 8'd0)
			begin
				led_reg <= ~led_reg;
			end
			cnt2 <= cnt2 + 8'd1;
		end
		else
			cnt <= cnt + 20'd1;
			
	end

endmodule


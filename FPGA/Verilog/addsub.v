module addsub
(
	input [31:0] dataa,
	input [31:0] datab,
	input add_sub,	  // if this is 1, add; else subtract
	input clk,
	output reg [32:0] result
);

	always @ (posedge clk)
	begin
		if (add_sub)
			result <= dataa + datab;
		else
			result <= dataa - datab;
	end

endmodule

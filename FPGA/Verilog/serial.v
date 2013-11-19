// by teknohog, replaces virtual_wire by rs232

module serial_receive(clk, RxD, midstate, data2, reset, RxRDY, RxBUSY);
   input      clk;
   input      RxD;
	output 		RxBUSY;
   
   wire       RxD_data_ready;
   wire [7:0] RxD_data;

   async_receiver deserializer(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));

   output [255:0] midstate;
   output [95:0] data2;
	output RxRDY;
	
	reg [21:0] guard_cnt;

	//assign RxRDY = RxD_data_ready;

	
   // 256 bits midstate + 256 bits data at the same time = 64 bytes

   // Might be a good idea to add some fixed start and stop sequences,
   // so we really know we got all the data and nothing more. If a
   // test for these fails, should ask for new data, so it needs more
   // logic on the return side too. The check bits could be legible
   // 7seg for quick feedback :)

   // The above is related to a more general issue of messing up the
   // input buffers due to partial data. For example, when a serial
   // cable is disconnected and reconnected. A manual reset is a much
   // nicer remedy than complete reprogramming, and it has other uses
   // in a cluster.
   input 	  reset;
   
   reg [511:0] input_buffer;
//   reg [511:0] input_copy;
//   reg [6:0]   demux_state = 7'b0000000;

	reg [6:0] byte_cnt;
	assign RxRDY = byte_cnt[6];

	assign RxBUSY = (|byte_cnt[6:0]);

   assign midstate = input_buffer[511:256];
   assign data2 = input_buffer[95:0];
      
   always @(posedge clk)
	begin
		if(reset || RxRDY || (guard_cnt == 22'd0))
		begin
			byte_cnt <= 7'd0;
			guard_cnt <=22'd1;
		end
		else
			guard_cnt <= guard_cnt + 22'd1;
				
	    if(RxD_data_ready)
	      begin
				input_buffer <= input_buffer << 8;
				input_buffer[7:0] <= RxD_data;
				byte_cnt <= byte_cnt+1;
				guard_cnt <= 22'd1;
	      end
		else
			input_buffer <= input_buffer;
	end
endmodule // serial_receive

module serial_transmit (clk, TxD, busy, send, word);
   
   // split 4-byte output into bytes

   wire TxD_start;
   wire TxD_busy;
   
   reg [7:0]  out_byte;
   reg        serial_start;
   reg [3:0]  mux_state = 4'b0000;

   assign TxD_start = serial_start;

   input      clk;
   output     TxD;
   
   input [31:0] word;
   input 	send;
   output busy;
	
   reg [31:0] 	word_copy;
	reg [31:0] delay_cnt;
	
   assign busy = (|mux_state);

   always @(posedge clk)
     begin

	if (!busy && send)
	  begin
	     mux_state <= 4'b1000;
	     word_copy <= word;
		  delay_cnt[31:0] <= 32'd100000;
	  end  
	else
	begin
		begin
			if (mux_state[3] && ~mux_state[0] && !TxD_busy)
			  begin
				  serial_start <= 1;
				  mux_state <= mux_state + 1;

				  out_byte <= word_copy[31:24];
				  word_copy <= (word_copy << 8);
			  end
			
			// wait stages
			else if (mux_state[3] && mux_state[0])
			  begin
					serial_start <= 0;
					if (!TxD_busy) mux_state <= mux_state + 1;
			  end
			 end
		 end
	  end

   async_transmitter serializer(.clk(clk), .TxD(TxD), .TxD_start(TxD_start), .TxD_data(out_byte), .TxD_busy(TxD_busy));
endmodule // serial_send

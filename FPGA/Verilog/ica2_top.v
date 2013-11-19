`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:33:33 04/05/2013 
// Design Name: 
// Module Name:    ica2_top 
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

`undef WITH_PROTOCOL_ANALYZER

module ica2_top(USER_CLK, SW, LED2, LED3, LED4, LED5, USB_RXD, /* LED_OUT, POS_OUT,*/ TX_P0, TX_M0, RX_P0, RX_M0, TX_P1, TX_M1, RX_P1, RX_M1, USB_TXD);

	input USER_CLK;
	input [2:0] SW;
	output LED2;
	output LED3;
	output LED4;
	output LED5;
	output USB_RXD;
//	output [6:0] LED_OUT;
//	output [3:0] POS_OUT;
	output TX_P0;
	output TX_M0;
	input RX_P0;
	input RX_M0;
	output TX_P1;
	output TX_M1;
	input RX_P1;
	input RX_M1;
	input USB_TXD;

//	reg [15:0] test_data;
	reg prev_led2;
	
	reg [31:0] mining_cnt;
	reg mining_led;
	
	assign LED2 = mining_led;
	
	parameter MODE_STANDBY = 8'h0b;
	parameter MODE_WORK = 8'h01;
	parameter MODE_SET_CLK = 8'h07;

	parameter PLL0_375 = 8'hb8;
	parameter PLL1_375 = 8'h0b;

	parameter PLL0_350 = 8'hf0;
	parameter PLL1_350 = 8'h0a;

	parameter PLL0_325 = 8'h28;
	parameter PLL1_325 = 8'h0a;

	parameter PLL0_300 = 8'h63;
	parameter PLL1_300 = 8'h09;

	parameter PLL0_282 = 8'hd3;
	parameter PLL1_282 = 8'h08;

	parameter PLL0_270 = 8'h73;
	parameter PLL1_270 = 8'h08;

	parameter PLL0_256 = 8'h03;
	parameter PLL1_256 = 8'h08;
	
	reg [7:0] pll0;
	reg [7:0] pll1;
	reg [7:0] pll0_prev;
	reg [7:0] pll1_prev;
	
	reg [7:0] mode;
	reg [7:0] mode_prev;

	wire led_clk;
	wire hb_led;
	
	heartbeat hb1 (.clk(USER_CLK), .led_clk(led_clk), .led(hb_led));
 /*  HexDisplayV1 hexdisplay (.sys_clk(USER_CLK), .value_in(test_data), .BCD_enable(1'b0), .Display_Enable(1'b1), 
										.sevenSegLED_out(LED_OUT[6:0]), .sevenSegPos_out(POS_OUT[3:0])); */
	
	reg [255:0] midstate_d;
	reg [95:0] data2_d;

	wire [255:0] midstate;
   wire [95:0] data2;
	wire serial_rx_ready;
	reg serial_rx_ready_prev;
	reg serial_rx_reset;
	wire serial_rx_busy;
	
	serial_receive serial_rx(.clk(USER_CLK), .RxD(USB_TXD), .midstate(midstate[255:0]), .data2(data2[95:0]), .reset(serial_rx_reset), .RxRDY(serial_rx_ready), .RxBUSY(serial_rx_busy));

	wire serial_tx_busy;
	reg zero;

	
	reg serial_tx_start;
	
	reg [31:0] delay_cnt;

	wire [575:0] data;
	assign data[575:0] = { sha_out[31:0], midstate_d[255:0], sha_out[223:192], sha_out[191:160], sha_out[159:128], sha_out[95:64], sha_out[63:32], data2_d[95:0], 8'h00, 8'h00, 8'h01, 8'h74 };
	reg ava_tx_start;
	wire ava_tx_busy;
	
	ava_tx ava_tx0 (.clk(USER_CLK), .start(ava_tx_start), .data(data[575:0]), .pll0(pll0), .pll1(pll1), .mode(mode), .busy(ava_tx_busy), .tx_p0(TX_P0), .tx_m0(TX_M0), .tx_p1(TX_P1), .tx_m1(TX_M1), .global_reset(1'b0));


	wire [31:0] nonce0;
	wire [31:0] true_nonce0;
	wire [31:0] nonce1;
	wire [31:0] true_nonce1;
	wire [31:0] true_nonce;
	reg [31:0] prev_true_nonce0;
	reg [31:0] prev_true_nonce1;

	wire is_dup_nonce = ((true_nonce == prev_true_nonce1) || 
								(true_nonce == prev_true_nonce0));
	wire nonce_ready;
	wire nonce_ready0;
	wire nonce_ready1;
	
	assign nonce_ready = (nonce_ready0 || nonce_ready1);
	assign true_nonce = (nonce_ready0 ? true_nonce0 : true_nonce1);
	
	reg nonce_latch0;
	reg nonce_latch1;
	
	nonce n0 (.clk(USER_CLK), .nonce(nonce0[31:0]), .true_nonce(true_nonce0[31:0]));
	nonce n1 (.clk(USER_CLK), .nonce(nonce1[31:0]), .true_nonce(true_nonce1[31:0]));
	
//	assign LED3 = nonce_ready;
	
	ava_rx ava_rx0 (.clk(USER_CLK), .rx_p(RX_P0), .rx_m(RX_M0), .data(nonce0[31:0]), .ready(nonce_ready0), .en(~nonce_latch0), .global_reset(serial_rx_ready));
	ava_rx ava_rx1 (.clk(USER_CLK), .rx_p(RX_P1), .rx_m(RX_M1), .data(nonce1[31:0]), .ready(nonce_ready1), .en(~nonce_latch1), .global_reset(serial_rx_ready));

	wire fifo_empty;
	wire [31:0] fifo_out;
	reg fifo_read;
	wire fifo_valid;


//	wire [31:0] golden_nonce;
	
//	fifo_generator_v8_2  fifo ( .clk(USER_CLK), .rst(), .din(true_nonce), .wr_en(nonce_ready && !is_dup_nonce), .rd_en(fifo_read), .dout(fifo_out), .full(), .empty(fifo_empty), .valid(fifo_valid));
//	serial_transmit tx (.clk(USER_CLK), .TxD(USB_RXD), .busy(serial_tx_busy), .send(fifo_valid), .word(fifo_out));

	serial_transmit tx (.clk(USER_CLK), .TxD(USB_RXD), .busy(serial_tx_busy), .send(nonce_ready && !is_dup_nonce && !(nonce_latch0 && nonce_latch1)), .word(true_nonce));

	wire[255:0] sha_out;
	
	sha256_pipe3 sha256 (.clk(USER_CLK), .state(midstate_d[255:0]), .state2(midstate_d[255:0]), .data({416'd0, data2_d[95:0]}), .hash(sha_out[255:0]));

	pwm_fade pf0 (.clk(USER_CLK), .trigger(nonce_ready0 && !is_dup_nonce && !nonce_latch), .drive(LED4)); 
	pwm_fade pf1 (.clk(USER_CLK), .trigger(nonce_ready1 && !is_dup_nonce && !nonce_latch), .drive(LED5)); 

//	hub_core hub0 (.hash_clk(USER_CLK), .new_nonces({(nonce_ready0 && !is_dup_nonce0), (nonce_ready1 && !is_dup_nonce1)}), .golden_nonce(golden_nonce), .serial_send(serial_tx_start), .serial_busy(serial_tx_busy), .slave_nonces({true_nonce0[31:0],true_nonce1[31:0]}));

	always @(posedge USER_CLK)
	begin

		mode_prev <= mode;

		pll0_prev <= pll0;
		pll1_prev <= pll1;

		case (SW[2:0])
			3'b000: 
				begin
					pll0 <= PLL0_256;
					pll1 <= PLL1_256;
				end
			3'b001:
				begin
					pll0 <= PLL0_270;
					pll1 <= PLL1_270;
				end			
			3'b010:
				begin
					pll0 <= PLL0_282;
					pll1 <= PLL1_282;
				end			
			3'b011:
				begin
					pll0 <= PLL0_300;
					pll1 <= PLL1_300;
				end
			3'b100:
				begin
					pll0 <= PLL0_325;
					pll1 <= PLL1_325;
				end
			3'b101:
				begin
					pll0 <= PLL0_350;
					pll1 <= PLL1_350;
				end
			3'b110:
				begin
					pll0 <= PLL0_375;
					pll1 <= PLL1_375;
				end
			default:
				begin
					pll0 <= PLL0_282;
					pll1 <= PLL1_282;
				end
		endcase
			
		if(nonce_ready)
		begin				
			prev_true_nonce1 <= prev_true_nonce0;
			prev_true_nonce0 <= true_nonce;		
	/*		if(nonce_ready0 && !is_dup_nonce)
				nonce_latch0 <= 1;
			else if(nonce_ready1 && !is_dup_nonce)
				nonce_latch1 <= 1; */
			if(!is_dup_nonce)
			begin
				nonce_latch0 <= 1;
				nonce_latch1 <= 1;
			end
		end
		
//		if(nonce_latch0 && nonce_latch1)
//			mining_cnt <= 32'h1531f00;
		
		if(serial_rx_ready)
		begin
//			prev_true_nonce1 <= 32'd0;
//			prev_true_nonce0 <= 32'd0;
		end

		if(mining_cnt != 32'd0)
			mining_cnt <= mining_cnt+1;

		if(ava_tx_start)
			ava_tx_start <= 0;
			
		if(serial_rx_reset)
			serial_rx_reset <= 0;

		if(mining_cnt == 32'h3fffffe)
		begin
			mode <= MODE_STANDBY;
			ava_tx_start <= 1;
			serial_rx_reset <= 1;
		end
		else
		begin
			if(mining_cnt == 32'd10)
			begin
//				if(((pll0_prev != pll0) || (pll1_prev != pll1)) || mode_prev == MODE_STANDBY)
//					mode <= MODE_SET_CLK;
//				else
				mode <= MODE_SET_CLK;
				ava_tx_start <= 1;
				nonce_latch0 <= 0;
				nonce_latch1 <= 0;
			end
			else
			begin
				if(mining_cnt > 32'h1fffff)
				begin
					mining_led <= 0;
				end
			end
		end
		
		serial_rx_ready_prev <= serial_rx_ready;
		if(!serial_rx_ready_prev && serial_rx_ready)
	//	if(serial_rx_ready)
		begin
			midstate_d[255:0] <= midstate[255:0];
			data2_d[95:0] <= data2[95:0];
			mining_led <= 1;
			mining_cnt <= 32'd1;
		end

		if(!fifo_empty && !serial_tx_busy)
			fifo_read <= 1;
		else
			fifo_read <= 0; 


	end

endmodule

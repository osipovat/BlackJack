// input to datapath = card number

// player1: KEY[0] bet, KEY[1] card
// player2: KEY[2] bet, KEY[3] card
// p1: SW[7] done
// p2: SW[1] done
module final(CLOCK_50, KEY, SW);
	input CLOCK_50;
	input [3:0] KEY; //player 1 hit buttons
	 //player 2 hit button
	input [9:0] SW; //end button for player 1
	//end button for player 2
	
	wire clk, resetn;
	assign clk = CLOCK_50;
	assign resetn = ~SW[9];

	wire ld_card, ld_bet, ld_card2, ld_bet2;
	wire done, done2;				// done_p1, done_p2;
	wire writeEn, ld_r;
	wire done_plot;

	
	wire [7:0] data_out1, data_out2;
	wire [7:0] test, test2;
	wire [7:0] total_bet, total_bet2, bet, bet2;
	wire [7:0] sum, sum2;
	wire [7:0] out_bet, out_bet2;

	// Declare your inputs and outputs here
	wire [2:0] coldata;

	wire [7:0] x;
	wire [6:0] y;

	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	vga_adapter VGA(
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(coldata),
		.x(x),
		.y(y),
		.plot(writeEn),
		// Signals for the DAC to drive the monitor. 
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "background.mif"; 
	wire [8:0] temp;
	datapath d0(.clk(clk),
		.resetn(resetn),
		.ld_card(ld_card),
		.ld_bet(ld_bet),
		.ld_card2(ld_card2),
		.ld_bet2(ld_bet2),
		.ld_r(ld_r),
		.done_bet(SW[7]),
		.done_bet2(SW[1]),
		.done_card(SW[6]),
		.done_card2(SW[2]),
		.plot(writeEn),
		.sum_out(data_out1),
		.sum_out2(data_out2),
		.show_bet(test),
		.show_bet2(test2),
		.totalBet(total_bet),
		.totalBet2(total_bet2),
		.summation(sum),
		.summation2(sum2),
		.betting(bet),
		.betting2(bet2),
		.wrout(out_bet),
		.wrout2(out_bet2),
		.xpos(x),
		.ypos(y),
		.color(coldata),
		.signal(done_plot),
		.cout(temp)
	);

	control c0 (.clk(clk),
		.done(done),
		.done2(done2),
		.done_bet1(SW[7]),
		.done_bet2(SW[1]),
		.done_card1(SW[6]),
		.done_card2(SW[2]),
		.resetn(resetn),
		.signal(done_plot),
    		.goBet(~KEY[0]), 
		.goCard(~KEY[1]), 
		.goBet2(~KEY[2]), 
		.goCard2(~KEY[3]),
		.ld_bet(ld_bet), 
		.ld_card(ld_card),
		.ld_bet2(ld_bet2), 
		.ld_card2(ld_card2),
		.plot(writeEn),
		.ld_r(ld_r)
    );

endmodule

module datapath(
		input clk,
		input resetn,
		input ld_card, ld_bet, ld_card2, ld_bet2,
		input ld_r,
		input done_bet, done_bet2, done_card, done_card2,
		input plot, 
		output [7:0] sum_out,
		output [7:0] sum_out2,
		output [7:0]show_bet, show_bet2,
		output [7:0] totalBet, totalBet2, //total bet is 100 initially, but the you bet and reduce it by your bet
		output [7:0] summation, summation2,
		output [7:0] betting, betting2,
		output [7:0] wrout, wrout2,
		output [7:0] xpos,
		output [6:0] ypos,
		output [2:0] color,
		output signal,
		output [8:0] cout
	    );
    	
	wire [3:0] num_in;
	reg [3:0] num;
	wire [1:0] shape_in;
	
   wire [15:0] card1, card2, card3, card4;
	
	reg [7:0] sum, sum2;
	reg [7:0] total_bet, total_bet2;
	initial total_bet = 8'd100;
	initial total_bet2 = 8'd100;
	reg [7:0] bet, bet2; // maximum bet is $50
	reg [7:0] bet_count, bet_count2;
	reg [7:0] card_count, card_count2;
	reg wren;
	wire [7:0] out_bet, out_bet2;
	wire [7:0] wr_bet, wr_bet2;
	reg [3:0] display_num;
	reg[1:0] display_col;
	reg [2:0] card_order, card_order2;
	reg [7:0] xcoord;
	reg [6:0] ycoord;

	//assign card1[14:13] = 2'd0;		// heart
	//assign card2[14:13] = 2'd1;		// spade
	//assign card3[14:13] = 2'd2;		// clover
	//assign card4[14:13] = 2'd3;		// diamond	

	randomNum num0(.clk(clk), .resetn(resetn), .rnd(num_in));
	randomShape sh0(.clk(clk), .resetn(resetn), .rnd(shape_in));
	
	bet_counter b0(.total_bet(total_bet), .total_bet2(total_bet2), .clk(clk), .wren(wren), .out_bet(out_bet), .out_bet2(out_bet2));

	// memory blocks for cards and colours
	// blue = spade, green = clover, red = heart, yellow = diamond
	// 4x1 mux for colours, 10x1 mux for numbers
	//reg [3:0] sel_num;
	reg [1:0] sel_col;
	reg [2:0] select;		// color input

	// outputs from an appropriate ram
	wire [2:0] yellow, green, blue, red;	
	wire [2:0] num1, num2, num3, num4, num5, num6, num7, num8, num9, num10;
	// display images
	reg [8:0] counter_out;
	assign cout = counter_out;
	wire [2:0] dummy;
	assign dummy = 2'd0;
	
	wire [8:0] ad;
	assign ad = counter_out;
	
	yellowram300x3 y0 (.address(ad),
		.clock(clk),
		.data(dummy),
		.wren(1'd0),
		.q(yellow));

    	greenram300x3 g0(.address(ad),
		.clock(clk),
		.data(dummy),
		.wren(1'd0),
		.q(green));

    	blueram300x3 blue0 (.address(ad),
			.clock(clk),
			.data(dummy),
			.wren(1'd0),
			.q(blue));

    	redram300x3 r0 (.address(ad),
		.clock(clk),
		.data(dummy),
		.wren(1'd0),
		.q(red));

	always @(sel_card) begin
		case (sel_card)
			4'd1: select = num1;
			4'd2: select = num2;
			4'd3: select = num3;
			4'd4: select = num4;
			4'd5: select = num5;
			4'd6: select = num6;
			4'd7: select = num7;
			4'd8: select = num8;
			4'd9: select = num9;
			4'd10: select = num10;
			default: select = num1;
		endcase
	end

	always @(sel_col)  begin
		case(sel_col)
			2'd0: select = blue;
			2'd1: select = green;
			2'd2: select = red;
			2'd3: select = yellow;
			default: select = yellow;
		endcase
	end
	assign color = select;

	assign xpos = xcoord + counter_out[3:0];
	assign ypos = ycoord + counter_out[8:4];

	//check the order of a card
	// set x and y to appropriate coordinates
	always@(card_order)
		case(card_order)
			3'd1: begin
				xcoord = 8'd10;
				ycoord = (ld_card) ? 7'd20 : 7'd60;
			end
			3'd2: begin
				xcoord = 8'd25;
				ycoord = (ld_card) ? 7'd20 : 7'd60;
			end
			3'd3: begin
				xcoord = 8'd40;
				ycoord = (ld_card) ? 7'd20 : 7'd60;
			end
			3'd4: begin
				xcoord = 8'd65;
				ycoord = (ld_card) ? 7'd20 : 7'd60;
			end
			3'd5: begin
				xcoord = 8'd90;
				ycoord = (ld_card) ? 7'd20 : 7'd60;
			end
		endcase

	// generate random card number
	always @(num_in)
    	case (num_in)
			4'd0: num = 4'd1;
			4'd1: num = 4'd1;
			4'd2: num = 4'd2;
			4'd3: num = 4'd3;
			4'd4: num = 4'd4;
			4'd5: num = 4'd5;
			4'd6: num = 4'd6;
			4'd7: num = 4'd7;
			4'd8: num = 4'd8;
			4'd9: num = 4'd9;
			4'd10: num = 4'd10;
			4'd11: num = 4'd10;
			4'd12: num = 4'd10;
			4'd13: num = 4'd10;
			4'd14: num = 4'd3;
			4'd15: num = 4'd10;
			default: num = 4'd1;
		endcase

	assign show_bet = bet_count;		// should be removed
	assign show_bet2 = bet_count2;		// should be removed
	// bet counter
	always @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			bet_count <= 0;
			bet_count2 <= 0;
			bet <= 0;
			bet2 <= 0;
		end
		else begin
			if (done_bet) begin
				bet <= bet_count;
			end
				
			if (done_bet2) begin
				bet2 <= bet_count2;

				
			end
			if (ld_bet)
				bet_count <= bet_count + 8'd5;
			if (ld_bet2)
				bet_count2 <= bet_count2 + 8'd5;
		end
	end

	always @(posedge clk, negedge resetn) begin
		if (~resetn) begin
			card_count <= 0;
			card_count2 <= 0;
			card_order <= 0;
			if (out_bet > 0) begin
				wren <= 0; //read total_bet and total_bet2
				total_bet <= out_bet;
				total_bet2 <= out_bet2;
			end
			sum <= 0;
			sum2 <= 0;
		end
		else begin
			if (ld_r) begin
				if ((sum < sum2) & (sum < 21) & (sum2 < 21)) begin //in the end need to consider differnt cases
				total_bet2 <= total_bet2 + bet;
				total_bet <= total_bet - bet;
				wren <= 1;
				end
			if ((sum > sum2) & (sum < 21) & (sum2 < 21)) begin
				total_bet <= total_bet + bet2;
				total_bet2 <= total_bet2 - bet2;
				wren <= 1;
			end
			
			
			if (sum == 21) begin
				total_bet <= total_bet + bet2;
				total_bet2 <= total_bet2 - bet2;
				wren <= 1;
			end
			if (sum2 == 21) begin
				total_bet2 <= total_bet2 + bet;
				total_bet <= total_bet - bet;
				wren <= 1;
			end
			
			if ((sum > sum2) & (sum > 21) & (sum2 > 21)) begin
				total_bet2 <= total_bet2 + bet;
				total_bet <= total_bet - bet;
				wren <= 1;
			end
			if ((sum < sum2) & (sum > 21) & (sum2 > 21)) begin
				total_bet <= total_bet + bet2;
				total_bet2 <= total_bet2 - bet2;
				wren <= 1;
			end
			if ((sum < sum2) & (sum < 21) & (sum2 > 21)) begin
				total_bet <= total_bet + bet2;
				total_bet2 <= total_bet2 - bet2;
				wren <= 1;
			end
			if ((sum > sum2) & (sum > 21) & (sum2 < 21)) begin
				total_bet2 <= total_bet2 + bet;
				total_bet <= total_bet - bet;
				wren <= 1;
			end
			end
			else begin
			if (done_card == 1)
				sum <= card_count;
				
			if (done_card2 == 1)
				sum2 <= card_count2;
				
		
			if (ld_card) begin
				card_count <= card_count + num;
				card_order <= card_order + 1'b1;
				sel_col <= shape_in ;
			end
			if (ld_card2) begin
				card_count2 <= card_count2 + num;
				card_order <= card_order + 1'b1;
				sel_col <= shape_in;
			end
			end
		end
	end

	always@(posedge clk) begin
		if (~resetn)
			counter_out <= 0;
		else begin
			if (counter_out == 9'd300)
				counter_out <= 0;
			else if (plot) begin
				counter_out <= counter_out + 1'b1;
			end
		end
	end
	assign signal = (counter_out == 9'd300);
	
	assign sum_out = card_count;
	assign sum_out2 = card_count2;
	assign totalBet = total_bet;
	assign totalBet2 = total_bet2;
	assign summation = sum;
	assign summation2 = sum2;
	assign betting = bet;
	assign betting2 = bet2;
	assign wrout = out_bet;
	assign wrout2 = out_bet2;

	
	
endmodule

module control(
    	input clk,
	input done, done2, done_bet1, done_bet2, done_card1, done_card2,
	input resetn, signal,
    	input goBet, goCard, goBet2, goCard2,

    	output reg ld_bet, ld_card, ld_bet2, ld_card2,
	output reg plot, ld_r
    	);

    	reg [3:0] current_state, next_state; 
    
    	localparam  	S_LOAD_BET    			= 5'd0,
			S_LOAD_B			= 5'd1,
			S_LOAD_B2			= 5'd2,
			S_CYCLE0			= 5'd3,
			S_LOAD_BET_WAIT   		= 5'd4,
			S_LOAD_BET2    			= 5'd5,
			S_LOAD_Bp2			= 5'd6,
			S_LOAD_B2p2			= 5'd7,
			S_CYCLE1			= 5'd8,
			S_LOAD_BET2_WAIT  		= 5'd9,
			S_LOAD_CARD       		= 5'd10,
			S_CYCLE2			= 5'd11,
			S_LOAD_CARD_WAIT  		= 5'd12,
			S_LOAD_WAIT			= 5'd13,
			S_LOAD_STOP 	  		= 5'd14,
			S_LOAD_CARD2      		= 5'd15,
			S_CYCLE3			= 5'd16,
			S_LOAD_CARD_WAIT2		= 5'd17,
			S_LOAD_WAIT2			= 5'd18,
			S_CYCLE4 	  		= 5'd19;
    	// Next state logic aka our state table
    	always@(*)
        begin: state_table 
            case (current_state)
            S_LOAD_BET: next_state = goBet ? S_LOAD_B2 : S_LOAD_B;        // player 1
            S_LOAD_B: next_state = goBet ? S_LOAD_B2 : S_LOAD_BET;
            S_LOAD_B2: next_state = done_bet1 ? S_CYCLE0 : S_LOAD_B2;
            S_CYCLE0: next_state = signal ? S_LOAD_BET_WAIT : S_CYCLE0;    // draw bet
            S_LOAD_BET_WAIT: next_state = goBet2 ? S_LOAD_BET_WAIT : S_LOAD_BET2;

            S_LOAD_BET2: next_state = goBet2 ? S_LOAD_B2p2 : S_LOAD_Bp2;        // player 2
            S_LOAD_Bp2: next_state = goBet2 ? S_LOAD_B2p2 : S_LOAD_BET2;
            S_LOAD_B2p2: next_state = done_bet2 ? S_CYCLE1 : S_LOAD_B2p2;
            S_CYCLE1: next_state = signal ? S_LOAD_BET2_WAIT : S_CYCLE1;    // draw bet
            S_LOAD_BET2_WAIT: next_state = goCard ? S_LOAD_BET2_WAIT : S_LOAD_CARD;
            
            S_LOAD_CARD: next_state = signal ? S_LOAD_CARD_WAIT : S_CYCLE2; //player 1
            S_CYCLE2: next_state = signal ? S_LOAD_CARD_WAIT : S_CYCLE2; //player 1
            S_LOAD_CARD_WAIT: next_state = goCard ? S_LOAD_WAIT : S_LOAD_CARD;
            S_LOAD_WAIT: next_state = done_card1 ? S_LOAD_STOP : S_LOAD_CARD_WAIT;
            S_LOAD_STOP: next_state = goCard2 ? S_LOAD_STOP : S_LOAD_CARD2;
            
            S_LOAD_CARD2: next_state = signal ? S_LOAD_CARD_WAIT2 : S_CYCLE3; //player 2
            S_CYCLE3: next_state = signal ? S_LOAD_CARD_WAIT2 : S_CYCLE3; //player 1
            S_LOAD_CARD_WAIT2: next_state = goCard2 ? S_LOAD_WAIT2 : S_LOAD_CARD2;
            S_LOAD_WAIT2: next_state = done_card2 ? S_CYCLE4 : S_LOAD_CARD_WAIT2;
          //  S_CYCLE4: next_state = signal ? S_CYCLE4 : S_LOAD_BET;
		S_CYCLE4: next_state = S_LOAD_BET;
                default: next_state = S_LOAD_BET;
                endcase
        end // state_table
  
	// Output logic aka all of our datapath control signals
        always @(*)
        	begin: enable_signals
         	ld_bet2 = 1'b0;
        	ld_card2 = 1'b0;
            	ld_bet = 1'b0;
        	ld_card = 1'b0;
            	plot = 1'b0;
        	ld_r = 1'b0;
    
            case (current_state)
		 S_LOAD_BET: begin
                    ld_bet = 1'b1;
                    end
      		 S_LOAD_B: begin
                    ld_bet = 1'b1;
                    end
               	 S_CYCLE0: begin
                       plot = 1'b1;
               	 	end
        	 S_LOAD_BET2: begin
                    ld_bet2 = 1'b1;
                	end
        	 S_LOAD_Bp2: begin
            		ld_bet2 = 1'b1;
            		end
            	 S_CYCLE1: begin
                	plot = 1'b1;
            		end

                 S_LOAD_CARD: begin
            		ld_card = 1'b1; 
      			end
        	 S_CYCLE2: begin 
            	 	plot = 1'b1; 
                        end

        	S_LOAD_CARD2: begin
            		ld_card2 = 1'b1;
                       end
        	S_CYCLE3: begin
           		 plot = 1'b1; 
                       end
        	S_CYCLE4: begin
            		ld_r = 1'b1; 
            		plot = 1'b1;
                    end
            endcase
        end // enable_signals
    	
   
    // current_state registers
    	always@(posedge clk)
    	begin: state_FFs
        	if(~resetn)
            	current_state <= S_LOAD_BET;
        	else
            	current_state <= next_state;
    	end // state_FFS
endmodule

module randomNum(
	input clk,
	input resetn,
	output [3:0] rnd);
	
	reg [7:0] random;

	wire feedback = random[6] ^ random[5];

	always@(posedge clk, negedge resetn)
	begin
		if (~resetn) begin
			random <= 8'hF;
		end
		else begin
			random <= {random[6:0], feedback};
		end
	end

	assign rnd = random[3:0];
	
endmodule

module randomShape(
	input clk,
	input resetn,
	output [1:0] rnd);
	
	reg [3:0] random;
	wire feedback = random[2] ^ random[3];

	always@(posedge clk, negedge resetn)
	begin
		if (~resetn) begin
			random <= 4'hF;
		end
		else begin
			random <= {random[2:0], feedback};
		end
	end
	assign rnd = random[1:0];	
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module bet_counter(total_bet, total_bet2, clk, wren, out_bet, out_bet2);
    input [7:0] total_bet;
    input [7:0] total_bet2;
    input clk;
    input wren;
    output [7:0] out_bet;
    output [7:0] out_bet2;
    
    ram32x8 r0(		// player 1 bet
	.address(8'd0),
	.clock(clk),
	.data(total_bet),
	.wren(wren),
	.q(out_bet)
	);


    ram32x8 r1(		// player 2 bet
	.address(8'd1),
	.clock(clk),
	.data(total_bet2),
	.wren(wren),
	.q(out_bet2)
	);


endmodule

module ram32x8 (
	address,
	clock,
	data,
	wren,
	q);

	input	[7:0]  address;
	input	  clock;
	input	[7:0]  data;
	input	  wren;
	output	[7:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 256,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 8,
		altsyncram_component.width_a = 8,
		altsyncram_component.width_byteena_a = 1;


endmodule


module TT(
    //Input Port
    clk,
    rst_n,
	in_valid,
    source,
    destination,

    //Output Port
    out_valid,
    cost
    );

input               clk, rst_n, in_valid;
input       [3:0]   source;
input       [3:0]   destination;

output          out_valid;
output  [3:0]   cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter IDLE      = 3'd0;
parameter INPUT_0	= 3'd1;
parameter INPUT		= 3'd2;
parameter TRAIN     = 3'd3;
parameter OUTPUT    = 3'd4;
parameter NEXT		= 3'd5;
parameter NO_STA	= 3'd6;
//==============================================//
//            FSM State Declaration             //
//==============================================//
reg [2:0] c_state;
reg [2:0] n_state;
//==============================================//
//                 reg declaration              //
//==============================================//
reg [3:0] start_point,end_point;

reg [3:0] sd_max,sd_min;
wire [3:0] sd_max_rev;
reg [0:15] pass_station;
reg pass_flag;
reg [3:0] cost_reg;

reg [14:0] connect_0_rev;
reg [13:0] connect_1_rev;
reg [12:0] connect_2_rev;
reg [11:0] connect_3_rev;
reg [10:0] connect_4_rev;
reg [ 9:0] connect_5_rev;
reg [ 8:0] connect_6_rev;
reg [ 7:0] connect_7_rev;
reg [ 6:0] connect_8_rev;
reg [ 5:0] connect_9_rev;
reg [ 4:0] connect_10_rev;
reg [ 3:0] connect_11_rev;
reg [ 2:0] connect_12_rev;
reg [ 1:0] connect_13_rev;
reg  [0:0] connect_14_rev;

wire [0:15] connect_0;
wire [0:15] connect_1;
wire [0:15] connect_2;
wire [0:15] connect_3;
wire [0:15] connect_4;
wire [0:15] connect_5;
wire [0:15] connect_6;
wire [0:15] connect_7;
wire [0:15] connect_8;
wire [0:15] connect_9;
wire [0:15] connect_10;
wire [0:15] connect_11;
wire [0:15] connect_12;
wire [0:15] connect_13;
wire [0:15] connect_14;
wire [0:15] connect_15;


//==============================================//
//             Current State Block              //
//==============================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state <= IDLE; /* initial state */
    else 
        c_state <= n_state;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@(*) begin
    case(c_state)
		IDLE :  n_state = (in_valid) ? INPUT_0 : IDLE ;
		INPUT_0: n_state = (in_valid) ? INPUT : NO_STA;
		INPUT : n_state = (in_valid) ? INPUT : ((pass_flag) ? NEXT : TRAIN);
		NEXT : n_state = OUTPUT ;
		NO_STA : n_state = OUTPUT;
        TRAIN : n_state = ( cost_reg==15 || pass_station[end_point]) ? OUTPUT : TRAIN ;
		default : n_state = IDLE;
    endcase
end

//==============================================//
//                  Input Block                 //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        end_point <= 0; /* remember to reset */
    else if(n_state==INPUT_0)begin
		end_point <= destination;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        start_point <= 0; /* remember to reset */
    else if(n_state==INPUT_0)begin
		start_point <= source;
    end
end

always@(*) begin
    if(!rst_n) begin
        sd_min = 0; /* remember to reset */
		sd_max = 0;
	end
    else if(in_valid)begin
		if(source<destination) begin
			sd_min = source;
			sd_max = destination;
		end
		else begin
			sd_min = destination;
			sd_max = source;
		end
	end
	else begin
		sd_min = 0;
		sd_max = 0;
	end
end

assign sd_max_rev = 15 - sd_max ; 

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        connect_0_rev <= 0;
		connect_1_rev <= 0; 
		connect_2_rev <= 0; 
		connect_3_rev <= 0; 
		connect_4_rev <= 0; 
		connect_5_rev <= 0; 
		connect_6_rev <= 0; 
		connect_7_rev <= 0; 
		connect_8_rev <= 0; 
		connect_9_rev <= 0; 
		connect_10_rev <= 0; 
		connect_11_rev <= 0; 
		connect_12_rev <= 0; 
		connect_13_rev <= 0; 
		connect_14_rev <= 0; 
	end
    else begin
		case(n_state)
			IDLE : begin
				connect_0_rev <= 0;
				connect_1_rev <= 0; 
				connect_2_rev <= 0; 
				connect_3_rev <= 0; 
				connect_4_rev <= 0; 
				connect_5_rev <= 0; 
				connect_6_rev <= 0; 
				connect_7_rev <= 0; 
				connect_8_rev <= 0; 
				connect_9_rev <= 0; 
				connect_10_rev <= 0; 
				connect_11_rev <= 0; 
				connect_12_rev <= 0; 
				connect_13_rev <= 0; 
				connect_14_rev <= 0; 
			end
			INPUT : begin
				case(sd_min)
					4'd0 : connect_0_rev[sd_max_rev] <= 1;
					4'd1 : connect_1_rev[sd_max_rev] <= 1;
					4'd2 : connect_2_rev[sd_max_rev] <= 1;
					4'd3 : connect_3_rev[sd_max_rev] <= 1;
					4'd4 : connect_4_rev[sd_max_rev] <= 1;
					4'd5 : connect_5_rev[sd_max_rev] <= 1;
					4'd6 : connect_6_rev[sd_max_rev] <= 1;
					4'd7 : connect_7_rev[sd_max_rev] <= 1;
					4'd8 : connect_8_rev[sd_max_rev] <= 1;
					4'd9 : connect_9_rev[sd_max_rev] <= 1;
					4'd10: connect_10_rev[sd_max_rev] <= 1;
					4'd11: connect_11_rev[sd_max_rev] <= 1;
					4'd12: connect_12_rev[sd_max_rev] <= 1;
					4'd13: connect_13_rev[sd_max_rev] <= 1;
					4'd14: connect_14_rev[sd_max_rev] <= 1;
				endcase
			end
		endcase
    end
end

assign connect_0 = {1'b0,connect_0_rev[14:0]} ;
assign connect_1 = {connect_0_rev[14],1'b0,connect_1_rev[13:0]} ;
assign connect_2 = {connect_0_rev[13],connect_1_rev[13],1'b0,connect_2_rev[12:0]} ;
assign connect_3 = {connect_0_rev[12],connect_1_rev[12],connect_2_rev[12],1'b0,connect_3_rev[11:0]} ;
assign connect_4 = {connect_0_rev[11],connect_1_rev[11],connect_2_rev[11],connect_3_rev[11],1'b0,connect_4_rev[10:0]} ;
assign connect_5 = {connect_0_rev[10],connect_1_rev[10],connect_2_rev[10],connect_3_rev[10],connect_4_rev[10],1'b0,connect_5_rev[9:0]} ;
assign connect_6 = {connect_0_rev[9],connect_1_rev[9],connect_2_rev[9],connect_3_rev[9],connect_4_rev[9],connect_5_rev[9],1'b0,connect_6_rev[8:0]} ;
assign connect_7 = {connect_0_rev[8],connect_1_rev[8],connect_2_rev[8],connect_3_rev[8],connect_4_rev[8],connect_5_rev[8],connect_6_rev[8],1'b0,connect_7_rev[7:0]} ;
assign connect_8 = {connect_0_rev[7],connect_1_rev[7],connect_2_rev[7],connect_3_rev[7],connect_4_rev[7],connect_5_rev[7],connect_6_rev[7],connect_7_rev[7],1'b0,connect_8_rev[6:0]} ;
assign connect_9 = {connect_0_rev[6],connect_1_rev[6],connect_2_rev[6],connect_3_rev[6],connect_4_rev[6],connect_5_rev[6],connect_6_rev[6],connect_7_rev[6],connect_8_rev[6],1'b0,connect_9_rev[5:0]};
assign connect_10 = {connect_0_rev[5],connect_1_rev[5],connect_2_rev[5],connect_3_rev[5],connect_4_rev[5],connect_5_rev[5],connect_6_rev[5],connect_7_rev[5],connect_8_rev[5],connect_9_rev[5],1'b0,connect_10_rev[4:0]};
assign connect_11 = {connect_0_rev[4],connect_1_rev[4],connect_2_rev[4],connect_3_rev[4],connect_4_rev[4],connect_5_rev[4],connect_6_rev[4],connect_7_rev[4],connect_8_rev[4],connect_9_rev[4],connect_10_rev[4],1'b0,connect_11_rev[3:0]};
assign connect_12 = {connect_0_rev[3],connect_1_rev[3],connect_2_rev[3],connect_3_rev[3],connect_4_rev[3],connect_5_rev[3],connect_6_rev[3],connect_7_rev[3],connect_8_rev[3],connect_9_rev[3],connect_10_rev[3],connect_11_rev[3],1'b0,connect_12_rev[2:0]};
assign connect_13 = {connect_0_rev[2],connect_1_rev[2],connect_2_rev[2],connect_3_rev[2],connect_4_rev[2],connect_5_rev[2],connect_6_rev[2],connect_7_rev[2],connect_8_rev[2],connect_9_rev[2],connect_10_rev[2],connect_11_rev[2],connect_12_rev[2],1'b0,connect_13_rev[1:0]};
assign connect_14 = {connect_0_rev[1],connect_1_rev[1],connect_2_rev[1],connect_3_rev[1],connect_4_rev[1],connect_5_rev[1],connect_6_rev[1],connect_7_rev[1],connect_8_rev[1],connect_9_rev[1],connect_10_rev[1],connect_11_rev[1],connect_12_rev[1],connect_13_rev[1],1'b0,connect_14_rev[0]};
assign connect_15 = {connect_0_rev[0],connect_1_rev[0],connect_2_rev[0],connect_3_rev[0],connect_4_rev[0],connect_5_rev[0],connect_6_rev[0],connect_7_rev[0],connect_8_rev[0],connect_9_rev[0],connect_10_rev[0],connect_11_rev[0],connect_12_rev[0],connect_13_rev[0],connect_14_rev[0], 1'b0};

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		pass_flag <= 0;
	end
	else if(n_state==INPUT) begin
		if( (start_point==source&&end_point==destination) || (start_point==destination&&end_point==source)) begin
			pass_flag <= 1;
		end
	end
	else pass_flag <= 0;
end


//==============================================//
//              Calculation Block               //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        pass_station <= 0; /* remember to reset */
    else begin
		case(n_state)
			IDLE : pass_station <= 0;
			INPUT_0 : pass_station[source] <= 1;
			TRAIN : begin
				pass_station <= pass_station			|
				({16{pass_station[0]}} & connect_0)		|
				({16{pass_station[1]}} & connect_1)		|
				({16{pass_station[2]}} & connect_2)		|
				({16{pass_station[3]}} & connect_3)		|
				({16{pass_station[4]}} & connect_4)		|
				({16{pass_station[5]}} & connect_5)		|
				({16{pass_station[6]}} & connect_6)		|
				({16{pass_station[7]}} & connect_7)		|
				({16{pass_station[8]}} & connect_8)		|
				({16{pass_station[9]}} & connect_9)		|
				({16{pass_station[10]}} & connect_10)	|
				({16{pass_station[11]}} & connect_11)	|
				({16{pass_station[12]}} & connect_12)	|
				({16{pass_station[13]}} & connect_13)	|
				({16{pass_station[14]}} & connect_14)	|
				({16{pass_station[15]}} & connect_15)	
				;
			end
		endcase
    end
end

//==============================================//
//                Output Block                  //
//==============================================//

assign out_valid = (n_state==OUTPUT)? 1 : 0;
assign cost = (cost_reg==15&& !pass_station[end_point])? 0 : cost_reg;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cost_reg <= 0; 
    else begin
		case(n_state)
			INPUT : begin
				if(pass_flag)
					cost_reg <= 1 ;
				else 
					cost_reg <= 0;
			end
			TRAIN : cost_reg <= cost_reg + 1;
			NEXT : cost_reg <= 1;
			OUTPUT : begin
				if(pass_station[end_point])
					cost_reg <= cost_reg;
				else
					cost_reg <= 0;
			end
			default : cost_reg <= 0;
		endcase		
    end
end 

endmodule 
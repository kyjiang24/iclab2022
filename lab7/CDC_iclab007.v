`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
    clk2,
    clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

    //Output Port
    out_valid1,
    out_valid2,
	equal,
	exceed,
	winner
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input 		clk1, clk2, clk3, rst_n;
input 		in_valid1, in_valid2;
input [3:0]	user1, user2;

output reg	out_valid1, out_valid2;
output reg	equal, exceed, winner;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
//----clk1----

wire [3:0]user_valid;

reg [3:0]	user1_reg, user2_reg;
reg [4:0] user1_point,user2_point;
reg [5:0] point_table1 [10:0];

wire [3:0]point[13:0];

wire [6:0] top_equal1,top_exceed1,bottom1;

wire [6:0]equal_clk1,exceed_clk1;

reg [6:0]equal_reg,exceed_reg;
 
reg xor_flag,xor_flag_win;
wire flag,flag_win;
reg [4:0] curr_point;
reg [5:0] cnt_clk1,cnt_clk3;

reg [5:0] point_user1,point_user2;
reg win_cycle;
reg [5:0] cnt_card;

wire [1:0]winner_result;
reg [1:0]winner_result_reg;
//----clk2----

//----clk3----

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----
//----clk2----

//----clk3----

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

assign user_valid = (in_valid1) ? user1 : (in_valid2) ? user2 : 'd0;
//============================================
//   clk1 domain
//============================================

assign point[0 ]  = 0 ;
assign point[1 ]  = 1 ;
assign point[2 ]  = 2 ;
assign point[3 ]  = 3 ;
assign point[4 ]  = 4 ;
assign point[5 ]  = 5 ;
assign point[6 ]  = 6 ;
assign point[7 ]  = 7 ;
assign point[8 ]  = 8 ;
assign point[9 ]  = 9 ;
assign point[10]  = 10 ;
assign point[11]  = 1  ;
assign point[12]  = 1  ;
assign point[13]  = 1  ;

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		point_table1[10] <= 'd4 ;
		point_table1[9 ] <= 'd8 ;
		point_table1[8 ] <= 'd12;
		point_table1[7 ] <= 'd16;
		point_table1[6 ] <= 'd20;
		point_table1[5 ] <= 'd24;
		point_table1[4 ] <= 'd28 ;
		point_table1[3 ] <= 'd32 ;
		point_table1[2 ] <= 'd36 ;
		point_table1[1 ] <= 'd52 ;
		point_table1[0 ] <= 'd0 ;
	end
	else if(cnt_card==49) begin
		point_table1[10] <= 'd4 ;
		point_table1[9 ] <= 'd8 ;
		point_table1[8 ] <= 'd12;
		point_table1[7 ] <= 'd16;
		point_table1[6 ] <= 'd20;
		point_table1[5 ] <= 'd24;
		point_table1[4 ] <= 'd28 ;
		point_table1[3 ] <= 'd32 ;
		point_table1[2 ] <= 'd36 ;
		point_table1[1 ] <= 'd52 ;
		point_table1[0 ] <= 'd0 ;
	end 
	else begin
		case(point[user_valid])
			'd10: begin
				point_table1[10] <= point_table1[10] - 'd1;
				point_table1[9 ] <= point_table1[9 ] - 'd1;
				point_table1[8 ] <= point_table1[8 ] - 'd1;
				point_table1[7 ] <= point_table1[7 ] - 'd1;
				point_table1[6 ] <= point_table1[6 ] - 'd1;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd9: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] - 'd1;
				point_table1[8 ] <= point_table1[8 ] - 'd1;
				point_table1[7 ] <= point_table1[7 ] - 'd1;
				point_table1[6 ] <= point_table1[6 ] - 'd1;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd8: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] - 'd1;
				point_table1[7 ] <= point_table1[7 ] - 'd1;
				point_table1[6 ] <= point_table1[6 ] - 'd1;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd7: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] - 'd1;
				point_table1[6 ] <= point_table1[6 ] - 'd1;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd6: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] - 'd1;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd5: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] ;
				point_table1[5 ] <= point_table1[5 ] - 'd1;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd4: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] ;
				point_table1[5 ] <= point_table1[5 ] ;
				point_table1[4 ] <= point_table1[4 ] - 'd1;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd3: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] ;
				point_table1[5 ] <= point_table1[5 ] ;
				point_table1[4 ] <= point_table1[4 ] ;
				point_table1[3 ] <= point_table1[3 ] - 'd1;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd2: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] ;
				point_table1[5 ] <= point_table1[5 ] ;
				point_table1[4 ] <= point_table1[4 ] ;
				point_table1[3 ] <= point_table1[3 ] ;
				point_table1[2 ] <= point_table1[2 ] - 'd1;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
			'd1: begin
				point_table1[10] <= point_table1[10] ;
				point_table1[9 ] <= point_table1[9 ] ;
				point_table1[8 ] <= point_table1[8 ] ;
				point_table1[7 ] <= point_table1[7 ] ;
				point_table1[6 ] <= point_table1[6 ] ;
				point_table1[5 ] <= point_table1[5 ] ;
				point_table1[4 ] <= point_table1[4 ] ;
				point_table1[3 ] <= point_table1[3 ] ;
				point_table1[2 ] <= point_table1[2 ] ;
				point_table1[1 ] <= point_table1[1 ] - 'd1;
			end
		endcase
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_card <= 'd0;
	end 
	else if(in_valid1 || in_valid2) begin
		if(cnt_card==49)	
			cnt_card <= 'd0;
		else
			cnt_card <= cnt_card + 'd1 ;
	end
	else begin
		cnt_card <= 'd0;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		point_user1 <= 'd0;
	end 
	else if(cnt_clk1==0 && in_valid1)begin
		point_user1 <= point[user_valid];
	end
	else if(in_valid1)begin
		point_user1 <= point_user1 + point[user_valid];
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		point_user2 <= 'd0;
	end 
	else if(in_valid1) begin
		point_user2 <= 'd0;
	end
	else if(in_valid2)begin
		point_user2 <= point_user2 + point[user_valid];
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user1_reg <= 'd0;
	end 
	else if(in_valid1)begin
		user1_reg <= user_valid;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user2_reg <= 'd0;
	end 
	else if(in_valid2)begin
		user2_reg <= user_valid;
	end
end


assign bottom1 = point_table1[1];
assign top_equal1 = (curr_point>10) ? 'd0 : (curr_point==10) ? point_table1[curr_point] : point_table1[curr_point] - point_table1[curr_point+1];
assign top_exceed1 =  (curr_point>9) ? 'd0 : point_table1[curr_point+1];
assign equal_clk1 = (curr_point==0) ? 'd0 : top_equal1*100 / bottom1;
assign exceed_clk1 = (curr_point==0) ? 'd100 : top_exceed1*100 / bottom1;

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		curr_point <= 'd21;
	end 
	else if(in_valid1 || in_valid2)begin
		if(cnt_clk1==0)
			curr_point <= 'd21 - point[user_valid];
		else if(curr_point < point[user_valid])
			curr_point <= 'd0;
		else
			curr_point <= curr_point - point[user_valid];
	end
	else begin
		curr_point <= 'd21;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user1_point <= 'd21;
	end 
	else if(cnt_clk1==0) begin
		if(in_valid1==0)
			user1_point <= curr_point;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		user2_point <= 'd21;
	end 
	else if(cnt_clk1==0 && in_valid2==0) begin
		user2_point <= curr_point;
	end
end

assign winner_result =	(point_user1=='d21 && point_user2=='d21) ? 'd0 :
						(point_user1=='d21) ? 'd2 :
						(point_user2=='d21) ? 'd3 :
						(user1_point==curr_point) ? 'd0 : 
						(point_user1>'d21) ? 'd3 :
						(point_user2>'d21) ? 'd2 :
						(user1_point<curr_point) ? 'd2 : 'd3;

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		winner_result_reg <= 'd0;
	end 
	else begin
		winner_result_reg <= winner_result;
	end
end
//assign winner_result = (user1_point<user2_point) ? 'd2 : (user1_point>user2_point) ? 'd3 : 'd0;

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		equal_reg <= 'd0;
	end 
	else begin
		equal_reg <= equal_clk1;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		exceed_reg <= 'd0;
	end 
	else begin
		exceed_reg <= exceed_clk1;
	end
end


always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_clk1 <= 'd0;
	end 
	else if(in_valid1 || in_valid2) begin
		if(cnt_clk1== 'd4)
			cnt_clk1 <= 'd0;
		else
			cnt_clk1 <= cnt_clk1 + 'd1 ;
	end
	else begin
		cnt_clk1 <= 'd0;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		xor_flag <= 'd0;
	end 
	else if(cnt_clk1==2 || cnt_clk1==3) begin
		xor_flag <= 'd1 ;
	end
	else begin
		xor_flag <= 'd0;
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		xor_flag_win <= 'd0;
	end 
	else if(cnt_clk1==4 && in_valid2) begin
		xor_flag_win <= 'd1 ;
	end
	else begin
		xor_flag_win <= 'd0;
	end
end
/*
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		
	end else begin
		
	end
end
*/
//============================================
//   clk2 domain
//============================================
always@(posedge clk2 or negedge rst_n) begin
	if(!rst_n) begin
		
	end 
	else begin
		
	end
end
//============================================
//   clk3 domain
//============================================

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		cnt_clk3 <= 'd0;
	end 
	else if(cnt_clk3==6) begin
		cnt_clk3 <= 'd0;
	end
	else if(flag || cnt_clk3!=0) begin
		cnt_clk3 <= cnt_clk3 + 'd1 ;
	end
	else begin
		cnt_clk3 <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		win_cycle <= 'd0;
	end 
	else if(cnt_clk3==1) begin
		win_cycle <= 'd0;
	end
	else if(flag_win && (winner_result_reg==2 || winner_result_reg==3)) begin
		win_cycle <=  'd1 ;
	end
	else begin
		win_cycle <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid1 <= 'd0;
	end
	else if(flag || cnt_clk3!=0) begin
		out_valid1 <= 'd1;
	end 
	else begin
		out_valid1 <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid2 <= 'd0;
	end
	else if(flag_win || win_cycle) begin
		out_valid2 <= 'd1;
	end 
	else begin
		out_valid2 <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		equal <= 'd0;
	end 
	else if(flag || cnt_clk3!=0) begin
		equal <= equal_reg[6-cnt_clk3];
	end 
	else begin
		equal <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		exceed <= 'd0;
	end
	else if(flag || cnt_clk3!=0) begin
		exceed <= exceed_reg[6-cnt_clk3];
	end 
	else begin
		exceed <= 'd0;
	end
end

always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		winner <= 'd0;
	end 
	else if(flag_win || win_cycle) begin
		winner <= winner_result_reg[~win_cycle];
	end
	else begin
		winner <= 'd0;
	end
end

/*
always@(posedge clk3 or negedge rst_n) begin
	if(!rst_n) begin
		
	end else begin
		
	end
end
*/
//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
syn_XOR u_syn_XOR1(.IN(xor_flag),.OUT(flag),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));

syn_XOR u_syn_XOR2(.IN(xor_flag_win),.OUT(flag_win),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));

//syn_XOR u_syn_XOR(.IN(),.OUT(),.TX_CLK(),.RX_CLK(),.RST_N());

endmodule
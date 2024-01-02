module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_u,
	in_valid_w,
	in_valid_v,
	in_valid_x,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

parameter one = 32'b00111111100000000000000000000000;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_u, in_valid_w, in_valid_v, in_valid_x;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------


reg [inst_sig_width+inst_exp_width:0] u_matrix[0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] v_matrix[0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] w_matrix[0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] x_matrix[0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] h_matrix[0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] y_matrix[0:1][0:2];
reg [inst_sig_width+inst_exp_width:0] mul1_in11,mul1_in12,mul1_in21,mul1_in22,mul1_in31,mul1_in32;
reg [inst_sig_width+inst_exp_width:0] mul2_in11,mul2_in12,mul2_in21,mul2_in22,mul2_in31,mul2_in32;
reg [inst_sig_width+inst_exp_width:0] mul3_in11,mul3_in12,mul3_in21,mul3_in22,mul3_in31,mul3_in32;
wire [inst_sig_width+inst_exp_width:0] mul1_out1,mul1_out2,mul1_out3;
wire [inst_sig_width+inst_exp_width:0] mul2_out1,mul2_out2,mul2_out3;
wire [inst_sig_width+inst_exp_width:0] mul3_out1,mul3_out2,mul3_out3;
wire [inst_sig_width+inst_exp_width:0] add1_out1,add1_out2;
wire [inst_sig_width+inst_exp_width:0] add2_out1,add2_out2;
wire [inst_sig_width+inst_exp_width:0] add3_out1,add3_out2;
wire [inst_sig_width+inst_exp_width:0] vh_relu;
wire [inst_sig_width+inst_exp_width:0] uw_wire;
reg [inst_sig_width+inst_exp_width:0] uw_neg_reg;
wire [inst_sig_width+inst_exp_width:0] exp_uw;
reg [inst_sig_width+inst_exp_width:0] exp_uw_reg;
wire [inst_sig_width+inst_exp_width:0] one_exp,sigmoid;
reg [inst_sig_width+inst_exp_width:0] sigmoid_reg;
reg [1:0] cnt_x,cnt_y;
reg [4:0] cnt;

integer i,j;


//==============================================//
//              INPUT Block                		//
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<3;i=i+1)
			for(j=0;j<3;j=j+1)
				u_matrix[i][j] <= 32'd0;
	end
	else if(in_valid_u)begin
		u_matrix[cnt_y][cnt_x] <= weight_u;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<3;i=i+1)
			for(j=0;j<3;j=j+1)
				v_matrix[i][j] <= 32'd0;
	end
	else if(in_valid_v)begin
		v_matrix[cnt_y][cnt_x] <= weight_v;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<3;i=i+1)
			for(j=0;j<3;j=j+1)
				w_matrix[i][j] <= 32'd0;
	end
	else if(in_valid_w)begin
		w_matrix[cnt_y][cnt_x] <= weight_w;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<3;i=i+1)
			for(j=0;j<3;j=j+1)	
				x_matrix[i][j] <= 32'd0;
	end
	else if(in_valid_x)begin
		x_matrix[cnt_y][cnt_x] <= data_x;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt_x <= 0;
		cnt_y <= 0;
	end
	else if(in_valid_w)begin
		if(cnt_x==2'd2) begin
			cnt_y <= cnt_y + 2'd1;
			cnt_x <= 'd0;
		end
		else begin
			cnt_x <= cnt_x + 2'd1;
		end
	end
	else begin
		cnt_x <= 0;
		cnt_y <= 0;
	end
end
//==============================================//
//              COMPUTE Block                	//
//==============================================//

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt <= 'd0;
	end
	else if( (cnt_y== 2'd2 && cnt_x== 2'd1) || !in_valid_x)begin
		if(cnt== 5'd17)	cnt <= 0;
		else	cnt <= cnt + 'd1;
	end
	else begin
		cnt <= 'd0;
	end
end

// U * x
always@(*) begin
    case(cnt)
    5'd0 : mul1_in11 = u_matrix[0][0];
    5'd1 : mul1_in11 = u_matrix[1][0];
    5'd2 : mul1_in11 = u_matrix[2][0];
    5'd5 : mul1_in11 = u_matrix[0][0];
    5'd6 : mul1_in11 = u_matrix[1][0];
    5'd7 : mul1_in11 = u_matrix[2][0];
    5'd10: mul1_in11 = u_matrix[0][0];
    5'd11: mul1_in11 = u_matrix[1][0];
    5'd12: mul1_in11 = u_matrix[2][0];
    default : mul1_in11 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul1_in21 = u_matrix[0][1];
    5'd1 : mul1_in21 = u_matrix[1][1];
    5'd2 : mul1_in21 = u_matrix[2][1];
    5'd5 : mul1_in21 = u_matrix[0][1];
    5'd6 : mul1_in21 = u_matrix[1][1];
    5'd7 : mul1_in21 = u_matrix[2][1];
    5'd10: mul1_in21 = u_matrix[0][1];
    5'd11: mul1_in21 = u_matrix[1][1];
    5'd12: mul1_in21 = u_matrix[2][1];
    default : mul1_in21 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul1_in31 = u_matrix[0][2];
    5'd1 : mul1_in31 = u_matrix[1][2];
    5'd2 : mul1_in31 = u_matrix[2][2];
    5'd5 : mul1_in31 = u_matrix[0][2];
    5'd6 : mul1_in31 = u_matrix[1][2];
    5'd7 : mul1_in31 = u_matrix[2][2];
    5'd10: mul1_in31 = u_matrix[0][2];
    5'd11: mul1_in31 = u_matrix[1][2];
    5'd12: mul1_in31 = u_matrix[2][2];
    default : mul1_in31 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul1_in12 = x_matrix[0][0];
    5'd1 : mul1_in12 = x_matrix[0][0];
    5'd2 : mul1_in12 = x_matrix[0][0];
    5'd5 : mul1_in12 = x_matrix[1][0];
    5'd6 : mul1_in12 = x_matrix[1][0];
    5'd7 : mul1_in12 = x_matrix[1][0];
    5'd10: mul1_in12 = x_matrix[2][0];
    5'd11: mul1_in12 = x_matrix[2][0];
    5'd12: mul1_in12 = x_matrix[2][0];
    default : mul1_in12 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul1_in22 = x_matrix[0][1];
    5'd1 : mul1_in22 = x_matrix[0][1];
    5'd2 : mul1_in22 = x_matrix[0][1];
    5'd5 : mul1_in22 = x_matrix[1][1];
    5'd6 : mul1_in22 = x_matrix[1][1];
    5'd7 : mul1_in22 = x_matrix[1][1];
    5'd10: mul1_in22 = x_matrix[2][1];
    5'd11: mul1_in22 = x_matrix[2][1];
    5'd12: mul1_in22 = x_matrix[2][1];
    default : mul1_in22 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul1_in32 = x_matrix[0][2];
    5'd1 : mul1_in32 = x_matrix[0][2];
    5'd2 : mul1_in32 = x_matrix[0][2];
    5'd5 : mul1_in32 = x_matrix[1][2];
    5'd6 : mul1_in32 = x_matrix[1][2];
    5'd7 : mul1_in32 = x_matrix[1][2];
    5'd10: mul1_in32 = x_matrix[2][2];
    5'd11: mul1_in32 = x_matrix[2][2];
    5'd12: mul1_in32 = x_matrix[2][2];
    default : mul1_in32 = 'd0;
    endcase
end

// W * h2
always@(*) begin
    case(cnt)
    5'd0 : mul2_in11 = w_matrix[0][0];
    5'd1 : mul2_in11 = w_matrix[1][0];
    5'd2 : mul2_in11 = w_matrix[2][0];
    5'd5 : mul2_in11 = w_matrix[0][0];
    5'd6 : mul2_in11 = w_matrix[1][0];
    5'd7 : mul2_in11 = w_matrix[2][0];
    5'd10: mul2_in11 = w_matrix[0][0];
    5'd11: mul2_in11 = w_matrix[1][0];
    5'd12: mul2_in11 = w_matrix[2][0];
    default : mul2_in11 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul2_in21 = w_matrix[0][1];
    5'd1 : mul2_in21 = w_matrix[1][1];
    5'd2 : mul2_in21 = w_matrix[2][1];
    5'd5 : mul2_in21 = w_matrix[0][1];
    5'd6 : mul2_in21 = w_matrix[1][1];
    5'd7 : mul2_in21 = w_matrix[2][1];
    5'd10: mul2_in21 = w_matrix[0][1];
    5'd11: mul2_in21 = w_matrix[1][1];
    5'd12: mul2_in21 = w_matrix[2][1];
    default : mul2_in21 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul2_in31 = w_matrix[0][2];
    5'd1 : mul2_in31 = w_matrix[1][2];
    5'd2 : mul2_in31 = w_matrix[2][2];
    5'd5 : mul2_in31 = w_matrix[0][2];
    5'd6 : mul2_in31 = w_matrix[1][2];
    5'd7 : mul2_in31 = w_matrix[2][2];
    5'd10: mul2_in31 = w_matrix[0][2];
    5'd11: mul2_in31 = w_matrix[1][2];
    5'd12: mul2_in31 = w_matrix[2][2];
    default : mul2_in31 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul2_in12 = 'd0;
    5'd1 : mul2_in12 = 'd0;
    5'd2 : mul2_in12 = 'd0;
    5'd5 : mul2_in12 = h_matrix[0][0];
    5'd6 : mul2_in12 = h_matrix[0][0];
    5'd7 : mul2_in12 = h_matrix[0][0];
    5'd10: mul2_in12 = h_matrix[1][0];
    5'd11: mul2_in12 = h_matrix[1][0];
    5'd12: mul2_in12 = h_matrix[1][0];
    default : mul2_in12 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul2_in22 = 'd0;
    5'd1 : mul2_in22 = 'd0;
    5'd2 : mul2_in22 = 'd0;
    5'd5 : mul2_in22 = h_matrix[0][1];
    5'd6 : mul2_in22 = h_matrix[0][1];
    5'd7 : mul2_in22 = h_matrix[0][1];
    5'd10: mul2_in22 = h_matrix[1][1];
    5'd11: mul2_in22 = h_matrix[1][1];
    5'd12: mul2_in22 = h_matrix[1][1];
    default : mul2_in22 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd0 : mul2_in32 = 'd0;
    5'd1 : mul2_in32 = 'd0;
    5'd2 : mul2_in32 = 'd0;
    5'd5 : mul2_in32 = h_matrix[0][2];
    5'd6 : mul2_in32 = h_matrix[0][2];
    5'd7 : mul2_in32 = h_matrix[0][2];
    5'd10: mul2_in32 = h_matrix[1][2];
    5'd11: mul2_in32 = h_matrix[1][2];
    5'd12: mul2_in32 = h_matrix[1][2];
    default : mul2_in32 = 'd0;
    endcase
end

//DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U01 ( .a(mul1_in11), .b(mul1_in12),  .c(mul1_in21), .d(mul1_in22), .e(mul1_in31), .f(mul1_in32), .rnd(3'b000), .z(add1_out2) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 ( .a(mul1_in11), .b(mul1_in12), .rnd(3'b000), .z(mul1_out1) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U2 ( .a(mul1_in21), .b(mul1_in22), .rnd(3'b000), .z(mul1_out2) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U3 ( .a(mul1_in31), .b(mul1_in32), .rnd(3'b000), .z(mul1_out3) );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  U4 ( .a(mul1_out1), .b(mul1_out2), .rnd(3'b000), .z(add1_out1) );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  U5 ( .a(mul1_out3), .b(add1_out1), .rnd(3'b000), .z(add1_out2) );

//DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) W01 ( .a(mul2_in11), .b(mul2_in12),  .c(mul2_in21), .d(mul2_in22), .e(mul2_in31), .f(mul2_in32), .rnd(3'b000), .z(add2_out2) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) W1 ( .a(mul2_in11), .b(mul2_in12), .rnd(3'b000), .z(mul2_out1) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) W2 ( .a(mul2_in21), .b(mul2_in22), .rnd(3'b000), .z(mul2_out2) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) W3 ( .a(mul2_in31), .b(mul2_in32), .rnd(3'b000), .z(mul2_out3) );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  W4 ( .a(mul2_out1), .b(mul2_out2), .rnd(3'b000), .z(add2_out1) );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  W5 ( .a(mul2_out3), .b(add2_out1), .rnd(3'b000), .z(add2_out2) );


DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) add1 ( .a(add1_out2), .b(add2_out2),  .rnd(3'b000),  .z(uw_wire) );

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		uw_neg_reg <= 'd0;
	end
	else begin
		uw_neg_reg <= {~uw_wire[31],uw_wire[30:0]};
	end
end

// e^x
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) exp1 ( .a(uw_neg_reg), .z(exp_uw));

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		exp_uw_reg <= 'd0;
	end
	else begin
		exp_uw_reg <= exp_uw;
	end
end

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) add2 (.a(exp_uw_reg), .b(one), .rnd(3'b000), .z(one_exp));
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) div1 (.a(one), .b(one_exp), .rnd(3'b000), .z(sigmoid));

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		sigmoid_reg <= 'd0;
	end
	else begin
		sigmoid_reg <= sigmoid;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<3;i=i+1)
			for(j=0;j<3;j=j+1)
				h_matrix[i][j] <= 32'd0;
	end
	else begin
		case(cnt)
			5'd2 : begin
				h_matrix[0][0] <= sigmoid;
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd3 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= sigmoid;
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd4 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= sigmoid;
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd7 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= sigmoid;
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd8 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= sigmoid;
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd9 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= sigmoid;
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd12: begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= sigmoid;
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd13 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= sigmoid;
				h_matrix[2][2] <= h_matrix[2][2];
			end
			5'd14 : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= sigmoid;
			end
			default : begin
				h_matrix[0][0] <= h_matrix[0][0];
				h_matrix[0][1] <= h_matrix[0][1];
				h_matrix[0][2] <= h_matrix[0][2];
				h_matrix[1][0] <= h_matrix[1][0];
				h_matrix[1][1] <= h_matrix[1][1];
				h_matrix[1][2] <= h_matrix[1][2];
				h_matrix[2][0] <= h_matrix[2][0];
				h_matrix[2][1] <= h_matrix[2][1];
				h_matrix[2][2] <= h_matrix[2][2];
			end
		endcase
	end
end

// V * h
always@(*) begin
    case(cnt)
    5'd5  : mul3_in11 = v_matrix[0][0];
    5'd6  : mul3_in11 = v_matrix[1][0];
    5'd7  : mul3_in11 = v_matrix[2][0];
    5'd10 : mul3_in11 = v_matrix[0][0];
    5'd11 : mul3_in11 = v_matrix[1][0];
    5'd12 : mul3_in11 = v_matrix[2][0];
    5'd15 : mul3_in11 = v_matrix[0][0];
    5'd16 : mul3_in11 = v_matrix[1][0];
    5'd17 : mul3_in11 = v_matrix[2][0];
    default : mul3_in11 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd5  : mul3_in21 = v_matrix[0][1];
    5'd6  : mul3_in21 = v_matrix[1][1];
    5'd7  : mul3_in21 = v_matrix[2][1];
    5'd10 : mul3_in21 = v_matrix[0][1];
    5'd11 : mul3_in21 = v_matrix[1][1];
    5'd12 : mul3_in21 = v_matrix[2][1];
    5'd15 : mul3_in21 = v_matrix[0][1];
    5'd16 : mul3_in21 = v_matrix[1][1];
    5'd17 : mul3_in21 = v_matrix[2][1];
    default : mul3_in21 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd5  : mul3_in31 = v_matrix[0][2];
    5'd6  : mul3_in31 = v_matrix[1][2];
    5'd7  : mul3_in31 = v_matrix[2][2];
    5'd10 : mul3_in31 = v_matrix[0][2];
    5'd11 : mul3_in31 = v_matrix[1][2];
    5'd12 : mul3_in31 = v_matrix[2][2];
    5'd15 : mul3_in31 = v_matrix[0][2];
    5'd16 : mul3_in31 = v_matrix[1][2];
    5'd17 : mul3_in31 = v_matrix[2][2];
    default : mul3_in31 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd5  : mul3_in12 = h_matrix[0][0];
    5'd6  : mul3_in12 = h_matrix[0][0];
    5'd7  : mul3_in12 = h_matrix[0][0];
    5'd10 : mul3_in12 = h_matrix[1][0];
    5'd11 : mul3_in12 = h_matrix[1][0];
    5'd12 : mul3_in12 = h_matrix[1][0];
    5'd15 : mul3_in12 = h_matrix[2][0];
    5'd16 : mul3_in12 = h_matrix[2][0];
    5'd17 : mul3_in12 = h_matrix[2][0];
    default : mul3_in12 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd5  : mul3_in22 = h_matrix[0][1];
    5'd6  : mul3_in22 = h_matrix[0][1];
    5'd7  : mul3_in22 = h_matrix[0][1];
    5'd10 : mul3_in22 = h_matrix[1][1];
    5'd11 : mul3_in22 = h_matrix[1][1];
    5'd12 : mul3_in22 = h_matrix[1][1];
    5'd15 : mul3_in22 = h_matrix[2][1];
    5'd16 : mul3_in22 = h_matrix[2][1];
    5'd17 : mul3_in22 = h_matrix[2][1];
    default : mul3_in22 = 'd0;
    endcase
end

always@(*) begin
    case(cnt)
    5'd5  : mul3_in32 = h_matrix[0][2];
    5'd6  : mul3_in32 = h_matrix[0][2];
    5'd7  : mul3_in32 = h_matrix[0][2];
    5'd10 : mul3_in32 = h_matrix[1][2];
    5'd11 : mul3_in32 = h_matrix[1][2];
    5'd12 : mul3_in32 = h_matrix[1][2];
    5'd15 : mul3_in32 = h_matrix[2][2];
    5'd16 : mul3_in32 = h_matrix[2][2];
    5'd17 : mul3_in32 = h_matrix[2][2];
    default : mul3_in32 = 'd0;
    endcase
end

DW_fp_dp3  #(inst_sig_width, inst_exp_width, inst_ieee_compliance) V01 ( .a(mul3_in11), .b(mul3_in12),  .c(mul3_in21), .d(mul3_in22), .e(mul3_in31), .f(mul3_in32), .rnd(3'b000), .z(add3_out2) );
//DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) V1 ( .a(mul3_in11), .b(mul3_in12), .rnd(3'b000), .z(mul3_out1) );
//DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) V2 ( .a(mul3_in21), .b(mul3_in22), .rnd(3'b000), .z(mul3_out2) );
//DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) V3 ( .a(mul3_in31), .b(mul3_in32), .rnd(3'b000), .z(mul3_out3) );
//DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  V4 ( .a(mul3_out1), .b(mul3_out2), .rnd(3'b000), .z(add3_out1) );
//DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  V5 ( .a(mul3_out3), .b(add3_out1), .rnd(3'b000), .z(add3_out2) );

assign vh_relu = add3_out2[31] ? 'd0 : add3_out2;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(i=0;i<2;i=i+1)
			for(j=0;j<3;j=j+1)	
				y_matrix[i][j] <= 32'd0;
	end
	else begin
		case(cnt)
			5'd5 : begin
				y_matrix[0][0] <= vh_relu;
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= y_matrix[1][2];
			end
			5'd6 : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= vh_relu;
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= y_matrix[1][2];
			end
			5'd7 : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= vh_relu;
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= y_matrix[1][2];
			end
			5'd10 : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= vh_relu;
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= y_matrix[1][2];
			end
			5'd11 : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= vh_relu;
				y_matrix[1][2] <= y_matrix[1][2];
			end
			5'd12 : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= vh_relu;
			end
			default : begin
				y_matrix[0][0] <= y_matrix[0][0];
				y_matrix[0][1] <= y_matrix[0][1];
				y_matrix[0][2] <= y_matrix[0][2];
				y_matrix[1][0] <= y_matrix[1][0];
				y_matrix[1][1] <= y_matrix[1][1];
				y_matrix[1][2] <= y_matrix[1][2];
			end
		endcase
	end
end

//==============================================//
//              OUTPUT Block                	//
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out <= 'd0;
	end
	else begin
		case(cnt)
			5'd9  : out <= y_matrix[0][0];
			5'd10 : out <= y_matrix[0][1];
			5'd11 : out <= y_matrix[0][2];
			5'd12 : out <= y_matrix[1][0];
			5'd13 : out <= y_matrix[1][1];
			5'd14 : out <= y_matrix[1][2];
			5'd15 : out <= vh_relu;
			5'd16 : out <= vh_relu;
			5'd17 : out <= vh_relu;
			default : out <= 'd0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 'd0;
	end
	else if(cnt>=5'd9)begin
		out_valid <= 'd1;
	end
	else out_valid <= 'd0;
end

endmodule
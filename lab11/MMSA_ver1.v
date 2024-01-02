module MMSA(
// input signals
    clk,
    rst_n,
    in_valid,
		in_valid2,
    matrix,
		matrix_size,
    i_mat_idx,
    w_mat_idx,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input 			 matrix;
input [1:0]  matrix_size;
input 			 i_mat_idx, w_mat_idx;

output reg       	     out_valid;//
output reg				 		 out_value;//
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter IDLE      =   4'd0;
parameter INPUT_0   =   4'd1;
parameter INPUT_1   =   4'd2;
parameter EMPTY     =   4'd6;
parameter INPUT_2   =   4'd3;
parameter CAL_IN    =   4'd4;
parameter CAL       =   4'd5;
parameter EMPTY2    =   4'd7;
parameter OUTPUT    =   4'd8;


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [3:0] ns,cs;
reg [1:0] m_size;//4
reg [3:0] m_element; //16
reg [6:0] mem_num; //128
reg [5:0] calout_num; //64
reg [63:0] in_64;

reg [3:0] calin_cycle;

reg [5:0] in_cnt_64; //64
reg [9:0] in_addr_cnt;
reg [4:0] in_matrix_cnt; //32
reg [7:0] in_cnt;
wire [63:0] mem_in_Q,mem_weight_Q;
wire [7:0] mem_in_A,mem_weight_A;

wire wen_in,wen_weight;
wire flag;
reg in_weight_flag;

wire [9:0] in_start_addr,weight_start_addr; //1024
reg [9:0] calin_addr,calweight_addr; //1024
reg [7:0] calin_cnt; //256
reg [7:0] cal_cnt;

reg [2:0] out_cnt_6;
reg [3:0] outset_cnt;
reg [3:0] out_cycle; //32
reg [4:0] calout_cnt; //32

reg [3:0] i_mat,w_mat;

reg [3:0] store_cnt;

wire [3:0] x_addr,y_addr; //16

reg signed[15:0] x_matrix[0:7][0:7];
reg signed[15:0] w_matrix[0:7][0:7];

reg signed [15:0] inA11,inA21,inA31,inA41,inA51,inA61,inA71,inA81;

wire signed [39:0] outC11,outC21,outC31,outC41,outC51,outC61,outC71,outC81;
wire signed [39:0] outC12,outC22,outC32,outC42,outC52,outC62,outC72,outC82;
wire signed [39:0] outC13,outC23,outC33,outC43,outC53,outC63,outC73,outC83;
wire signed [39:0] outC14,outC24,outC34,outC44,outC54,outC64,outC74,outC84;
wire signed [39:0] outC15,outC25,outC35,outC45,outC55,outC65,outC75,outC85;
wire signed [39:0] outC16,outC26,outC36,outC46,outC56,outC66,outC76,outC86;
wire signed [39:0] outC17,outC27,outC37,outC47,outC57,outC67,outC77,outC87;
wire signed [39:0] outC18,outC28,outC38,outC48,outC58,outC68,outC78,outC88;


wire signed [15:0] outD11,outD21,outD31,outD41,outD51,outD61,outD71,outD81;
wire signed [15:0] outD12,outD22,outD32,outD42,outD52,outD62,outD72,outD82;
wire signed [15:0] outD13,outD23,outD33,outD43,outD53,outD63,outD73,outD83;
wire signed [15:0] outD14,outD24,outD34,outD44,outD54,outD64,outD74,outD84;
wire signed [15:0] outD15,outD25,outD35,outD45,outD55,outD65,outD75,outD85;
wire signed [15:0] outD16,outD26,outD36,outD46,outD56,outD66,outD76,outD86;
wire signed [15:0] outD17,outD27,outD37,outD47,outD57,outD67,outD77,outD87;
wire signed [15:0] outD18,outD28,outD38,outD48,outD58,outD68,outD78,outD88;

reg signed [39:0] c_plus;
reg [5:0] length,out_cnt;
reg [5:0] length_reg[0:14];
wire [5:0] length_out;

wire length_value_flag; //length:0 value:1

reg signed [39:0] cal_out[0:14];
wire [39:0] value_out;
//==============================================//
//             Current State Block              //
//==============================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cs <= IDLE; 
    else 
        cs <= ns;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@(*) begin
    case(cs)
    IDLE    : ns = (in_valid) ? INPUT_0 : (in_valid2) ? INPUT_2 : IDLE ;
    INPUT_0 : ns = INPUT_1;
    INPUT_1 : ns = (in_valid)? INPUT_1 : EMPTY;
    EMPTY   : ns = (in_valid2)? INPUT_2 : EMPTY;
    INPUT_2 : ns = (in_valid2)? INPUT_2 : EMPTY2;
    EMPTY2  : ns = CAL_IN;
    CAL_IN  : ns = (calin_cnt==m_element)? CAL : CAL_IN;
    CAL     : ns = (store_cnt>out_cycle) ? OUTPUT : CAL;
    OUTPUT  : ns = (outset_cnt==out_cycle && out_cnt==0 && out_cnt_6==7) ? IDLE : OUTPUT;
    default : ns = IDLE;
    endcase
end

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//==============================================//
//              INPUT_1 Block                   //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_size <= 'd0;
    end
    else if(ns == INPUT_0)begin
        m_size <= matrix_size;
    end
end

always @(*) begin
    case(m_size)
        2'b00: m_element =  8'd0;
        2'b01: m_element =  8'd3;
        2'b10: m_element =  8'd15;
        default: m_element =  8'd0;
    endcase
end

/*
always @(*) begin
    case(m_size)
        2'b00: calin_cycle =  8'd0;
        2'b01: calin_cycle =  8'd3;
        2'b10: calin_cycle =  8'd15;
        default: calin_cycle =  8'd0;
    endcase
end
*/
always @(*) begin
    case(m_size)
        2'b00: mem_num =  7'd1;
        2'b01: mem_num =  7'd4;
        2'b10: mem_num =  7'd16;
        default: mem_num =  7'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: calout_num =  7'd1;
        2'b01: calout_num =  7'd1;
        2'b10: calout_num =  7'd7;
        default: calout_num =  7'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: calout_cnt =  'd3;
        2'b01: calout_cnt =  'd5;
        2'b10: calout_cnt =  'd9;
        default: calout_cnt =  'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: out_cycle =  'd2;
        2'b01: out_cycle =  'd6;
        2'b10: out_cycle =  'd14;
        default: out_cycle =  'd0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_cnt_64 <= 'd0;
    end
    else if(in_valid)begin
        in_cnt_64 <= in_cnt_64 + 'd1 ;
    end
    else begin
        in_cnt_64 <= 'd0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_cnt <= 8'd0;
    end
    else if(in_valid) begin
        if(in_cnt_64==63) begin
            if(in_cnt == m_element) 
                in_cnt <= 8'd0;
            else 
                in_cnt <= in_cnt + 8'd1 ;
        end
    end
    else begin
        in_cnt <= 8'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_matrix_cnt <= 5'd0;
    end
    else if(in_cnt_64==63 && in_cnt == m_element)begin
        in_matrix_cnt <= in_matrix_cnt + 5'd1 ;
    end
    else if(ns == IDLE)begin
        in_matrix_cnt <= 5'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_64 <= 'd0;
    end
    else if(in_valid) begin
        //in_64 <= {in_64[62:0],matrix};
        if(in_cnt_64==0)     in_64 <= matrix;
        else    in_64 <= {in_64[62:0],matrix};
    end
    else begin
        in_64 <= 'd0;
    end
end

assign flag = (in_addr_cnt==(mem_num<<4)-1) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_addr_cnt <= -1;
    end
    else if(in_valid) begin
        if(in_cnt_64==0) begin
            if(flag)    in_addr_cnt <= 0;   
            else    in_addr_cnt <= in_addr_cnt + 1;
        end
    end
    else begin
        in_addr_cnt <= -1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_weight_flag <= 1'b0;
    end
    else if (in_matrix_cnt>15) begin
        in_weight_flag <= 1'b1;
    end
    else if(ns==IDLE)begin
        in_weight_flag <= 1'b0;
    end
end

assign wen_in = (cs==INPUT_1 && in_cnt_64==0 && ~in_weight_flag) ? 1'b0 : 1'b1 ;
assign wen_weight = (cs==INPUT_1 && in_cnt_64==0 && in_weight_flag) ? 1'b0 : 1'b1 ;

//assign mem_in_A = (cs==INPUT_1) ? in_addr_cnt : (ns==CAL_IN) ? calin_addr  : 0; //can't use ns(combination?)
//assign mem_weight_A = (cs==INPUT_1) ? in_addr_cnt : (ns==CAL_IN) ? calweight_addr : 0;
assign mem_in_A = (cs==INPUT_1) ? in_addr_cnt :  calin_addr ;
assign mem_weight_A = (cs==INPUT_1) ? in_addr_cnt : calweight_addr ;


// 256 64 4 200
SRAM_256_64 MEM_IN (.Q(mem_in_Q), .CLK(clk), .CEN(1'b0), .WEN(wen_in), .A(mem_in_A), .D(in_64), .OEN(1'b0));
SRAM_256_64 MEM_WEIGHT (.Q(mem_weight_Q), .CLK(clk), .CEN(1'b0), .WEN(wen_weight), .A(mem_weight_A), .D(in_64), .OEN(1'b0));

//==============================================//
//              INPUT_2 Block                   //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i_mat <= 'd0;
    end
    else if(in_valid2) begin
        i_mat <= {i_mat[2:0],i_mat_idx};
    end
    else begin
        i_mat <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_mat <= 'd0;
    end
    else if(in_valid2) begin
        w_mat <= {w_mat[2:0],w_mat_idx};
    end
    else begin
        w_mat <= 'd0;
    end
end


assign in_start_addr = i_mat*mem_num ;
assign weight_start_addr = w_mat*mem_num ;

//==============================================//
//              CAL_IN Block                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calin_addr <= 'd0;
    end
    else if(ns == EMPTY2)begin
        calin_addr <= in_start_addr;
    end
    else if(ns == CAL_IN || cs == EMPTY2)begin
        calin_addr <= calin_addr + 1;
    end
    else begin
        calin_addr <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calweight_addr <= 'd0;
    end
    else if(ns == EMPTY2)begin
        calweight_addr <= weight_start_addr;
    end
    else if(ns == CAL_IN || cs == EMPTY2)begin
        calweight_addr <= calweight_addr + 1;
    end
    else begin
        calweight_addr <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calin_cnt <= 'd0;
    end
    else if(cs == CAL_IN)begin
        calin_cnt <= calin_cnt + 'd1;
    end
    else begin
        calin_cnt <= 'd0;
    end
end

assign x_addr = (m_size==2'b01) ? 0 :
                (m_size==2'b10) ? (calin_cnt<<2)%8 : 0;
assign y_addr = (m_size==2'b01) ? calin_cnt   : 
                (m_size==2'b10) ? calin_cnt>>1 : 0;

integer i;
integer j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0;i<8;i=i+1)
            for(j=0;j<8;j=j+1)
                x_matrix[i][j] <= 'd0;
    end
    else if(cs == CAL_IN)begin
        if(m_size==2'b00) begin
            x_matrix[0][0] <= mem_in_Q[63:48];
            x_matrix[0][1] <= mem_in_Q[47:32];
            x_matrix[1][0] <= mem_in_Q[31:16];
            x_matrix[1][1] <= mem_in_Q[15:0];
        end
        else begin
            x_matrix[y_addr][x_addr] <= mem_in_Q[63:48];
            x_matrix[y_addr][x_addr+1] <= mem_in_Q[47:32];
            x_matrix[y_addr][x_addr+2] <= mem_in_Q[31:16];
            x_matrix[y_addr][x_addr+3] <= mem_in_Q[15:0];
        end
    end
    else if(ns==IDLE) begin
        for(i=0;i<8;i=i+1)
            for(j=0;j<8;j=j+1)
                x_matrix[i][j] <= 'd0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0;i<8;i=i+1)
            for(j=0;j<8;j=j+1)
                w_matrix[i][j] <= 'd0;
    end
    else if(cs == CAL_IN)begin
        if(m_size==2'b00) begin
            w_matrix[0][0]  <= mem_weight_Q[63:48];
            w_matrix[0][1]  <= mem_weight_Q[47:32];
            w_matrix[1][0]  <= mem_weight_Q[31:16];
            w_matrix[1][1]  <= mem_weight_Q[15:0];
        end
        else begin
            w_matrix[y_addr][x_addr]  <= mem_weight_Q[63:48];
            w_matrix[y_addr][x_addr+1]  <= mem_weight_Q[47:32];
            w_matrix[y_addr][x_addr+2]  <= mem_weight_Q[31:16];
            w_matrix[y_addr][x_addr+3]  <= mem_weight_Q[15:0];
        end
    end
    else if(ns==IDLE) begin
        for(i=0;i<8;i=i+1)
            for(j=0;j<8;j=j+1)
                w_matrix[i][j] <= 'd0;
    end
end


//==============================================//
//              CAL Block                       //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cal_cnt <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        cal_cnt <= cal_cnt + 'd1;
    end
    else begin
        cal_cnt <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA11 <= 'd0;
    end
    else if(calin_cnt>calout_num || cs == CAL)begin
        case(cal_cnt)
            6'd0:  inA11 <= x_matrix[0 ][0];
            6'd1:  inA11 <= x_matrix[1 ][0];
            6'd2:  inA11 <= x_matrix[2 ][0];
            6'd3:  inA11 <= x_matrix[3 ][0];
            6'd4:  inA11 <= x_matrix[4 ][0];
            6'd5:  inA11 <= x_matrix[5 ][0];
            6'd6:  inA11 <= x_matrix[6 ][0];
            6'd7:  inA11 <= x_matrix[7 ][0];
            default : inA11 <= 'd0;
        endcase
    end
    else begin
        inA11 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA21 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd1:  inA21 <= x_matrix[0][1];
            6'd2:  inA21 <= x_matrix[1][1];
            6'd3:  inA21 <= x_matrix[2][1];
            6'd4:  inA21 <= x_matrix[3][1];
            6'd5:  inA21 <= x_matrix[4][1];
            6'd6:  inA21 <= x_matrix[5][1];
            6'd7:  inA21 <= x_matrix[6][1];
            6'd8 : inA21 <= x_matrix[7][1];
            default : inA21 <= 'd0;
        endcase
    end
    else begin
        inA21 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA31 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd2:  inA31 <= x_matrix[0][2];
            6'd3:  inA31 <= x_matrix[1][2];
            6'd4:  inA31 <= x_matrix[2][2];
            6'd5:  inA31 <= x_matrix[3][2];
            6'd6:  inA31 <= x_matrix[4][2];
            6'd7:  inA31 <= x_matrix[5][2];
            6'd8:  inA31 <= x_matrix[6][2];
            6'd9:  inA31 <= x_matrix[7][2];
            default : inA31 <= 'd0;
        endcase
    end
    else begin
        inA31 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA41 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd3 :  inA41 <= x_matrix[0][3];
            6'd4 :  inA41 <= x_matrix[1][3];
            6'd5 :  inA41 <= x_matrix[2][3];
            6'd6 :  inA41 <= x_matrix[3][3];
            6'd7 :  inA41 <= x_matrix[4][3];
            6'd8 :  inA41 <= x_matrix[5][3];
            6'd9 :  inA41 <= x_matrix[6][3];
            6'd10:  inA41 <= x_matrix[7][3];
            default : inA41 <= 'd0;
        endcase
    end
    else begin
        inA41 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA51 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd4 :  inA51 <= x_matrix[0][4];
            6'd5 :  inA51 <= x_matrix[1][4];
            6'd6 :  inA51 <= x_matrix[2][4];
            6'd7 :  inA51 <= x_matrix[3][4];
            6'd8 :  inA51 <= x_matrix[4][4];
            6'd9 :  inA51 <= x_matrix[5][4];
            6'd10:  inA51 <= x_matrix[6][4];
            6'd11:  inA51 <= x_matrix[7][4];
            default : inA51 <= 'd0;
        endcase
    end
    else begin
        inA51 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA61 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd5 :  inA61 <= x_matrix[0][5];
            6'd6 :  inA61 <= x_matrix[1][5];
            6'd7 :  inA61 <= x_matrix[2][5];
            6'd8 :  inA61 <= x_matrix[3][5];
            6'd9 :  inA61 <= x_matrix[4][5];
            6'd10:  inA61 <= x_matrix[5][5];
            6'd11:  inA61 <= x_matrix[6][5];
            6'd12:  inA61 <= x_matrix[7][5];
            default : inA61 <= 'd0;
        endcase
    end
    else begin
        inA61 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA71 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd6 :  inA71 <= x_matrix[0][6];
            6'd7 :  inA71 <= x_matrix[1][6];
            6'd8 :  inA71 <= x_matrix[2][6];
            6'd9 :  inA71 <= x_matrix[3][6];
            6'd10:  inA71 <= x_matrix[4][6];
            6'd11:  inA71 <= x_matrix[5][6];
            6'd12:  inA71 <= x_matrix[6][6];
            6'd13:  inA71 <= x_matrix[7][6];
            default : inA71 <= 'd0;
        endcase
    end
    else begin
        inA71 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA81 <= 'd0;
    end
    else if(calin_cnt>calout_num ||cs == CAL)begin
        case(cal_cnt)
            6'd7 :  inA81 <= x_matrix[0 ][7];
            6'd8 :  inA81 <= x_matrix[1 ][7];
            6'd9 :  inA81 <= x_matrix[2 ][7];
            6'd10:  inA81 <= x_matrix[3 ][7];
            6'd11:  inA81 <= x_matrix[4 ][7];
            6'd12:  inA81 <= x_matrix[5 ][7];
            6'd13:  inA81 <= x_matrix[6 ][7];
            6'd14:  inA81 <= x_matrix[7 ][7];
            default:inA81 <= 'd0;
        endcase
    end
    else begin
        inA81 <= 'd0;
    end
end


//PE PE1(.clk(clk),.rst_n(rst_n),.inA(),.inB(),.inW(),.outC(),.outD());

PE PE1_1 (.clk(clk),.rst_n(rst_n),.inA( inA11),.inB(40'd0),.inW(w_matrix[0][0]),.outC(outC11),.outD(outD11));
PE PE1_2 (.clk(clk),.rst_n(rst_n),.inA(outD11),.inB(40'd0),.inW(w_matrix[0][1]),.outC(outC12),.outD(outD12));
PE PE1_3 (.clk(clk),.rst_n(rst_n),.inA(outD12),.inB(40'd0),.inW(w_matrix[0][2]),.outC(outC13),.outD(outD13));
PE PE1_4 (.clk(clk),.rst_n(rst_n),.inA(outD13),.inB(40'd0),.inW(w_matrix[0][3]),.outC(outC14),.outD(outD14));
PE PE1_5 (.clk(clk),.rst_n(rst_n),.inA(outD14),.inB(40'd0),.inW(w_matrix[0][4]),.outC(outC15),.outD(outD15));
PE PE1_6 (.clk(clk),.rst_n(rst_n),.inA(outD15),.inB(40'd0),.inW(w_matrix[0][5]),.outC(outC16),.outD(outD16));
PE PE1_7 (.clk(clk),.rst_n(rst_n),.inA(outD16),.inB(40'd0),.inW(w_matrix  [0][6]),.outC(outC17),.outD(outD17));
PE PE1_8 (.clk(clk),.rst_n(rst_n),.inA(outD17),.inB(40'd0),.inW(  w_matrix[0][7]),.outC(outC18),.outD(outD18));

PE PE2_1 (.clk(clk),.rst_n(rst_n),.inA( inA21),.inB(outC11),.inW(w_matrix[1][0]),.outC(outC21),.outD(outD21));
PE PE2_2 (.clk(clk),.rst_n(rst_n),.inA(outD21),.inB(outC12),.inW(w_matrix[1][1]),.outC(outC22),.outD(outD22));
PE PE2_3 (.clk(clk),.rst_n(rst_n),.inA(outD22),.inB(outC13),.inW(w_matrix[1][2]),.outC(outC23),.outD(outD23));
PE PE2_4 (.clk(clk),.rst_n(rst_n),.inA(outD23),.inB(outC14),.inW(w_matrix[1][3]),.outC(outC24),.outD(outD24));
PE PE2_5 (.clk(clk),.rst_n(rst_n),.inA(outD24),.inB(outC15),.inW(w_matrix[1][4]),.outC(outC25),.outD(outD25));
PE PE2_6 (.clk(clk),.rst_n(rst_n),.inA(outD25),.inB(outC16),.inW(w_matrix[1][5]),.outC(outC26),.outD(outD26));
PE PE2_7 (.clk(clk),.rst_n(rst_n),.inA(outD26),.inB(outC17),.inW(w_matrix[1][6]),.outC(outC27),.outD(outD27));
PE PE2_8 (.clk(clk),.rst_n(rst_n),.inA(outD27),.inB(outC18),.inW(w_matrix[1][7]),.outC(outC28),.outD(outD28));

PE PE3_1(.clk(clk),.rst_n(rst_n),.inA(inA31),.inB(outC21),.inW(w_matrix[2][0]),.outC(outC31),.outD(outD31));
PE PE3_2(.clk(clk),.rst_n(rst_n),.inA(outD31),.inB(outC22),.inW(w_matrix[2][1]),.outC(outC32),.outD(outD32));
PE PE3_3(.clk(clk),.rst_n(rst_n),.inA(outD32),.inB(outC23),.inW(w_matrix[2][2]),.outC(outC33),.outD(outD33));
PE PE3_4(.clk(clk),.rst_n(rst_n),.inA(outD33),.inB(outC24),.inW(w_matrix[2][3]),.outC(outC34),.outD(outD34));
PE PE3_5(.clk(clk),.rst_n(rst_n),.inA(outD34),.inB(outC25),.inW(w_matrix[2][4]),.outC(outC35),.outD(outD35));
PE PE3_6(.clk(clk),.rst_n(rst_n),.inA(outD35),.inB(outC26),.inW(w_matrix[2][5]),.outC(outC36),.outD(outD36));
PE PE3_7(.clk(clk),.rst_n(rst_n),.inA(outD36),.inB(outC27),.inW(w_matrix[2][6]),.outC(outC37),.outD(outD37));
PE PE3_8(.clk(clk),.rst_n(rst_n),.inA(outD37),.inB(outC28),.inW(w_matrix[2][7]),.outC(outC38),.outD(outD38));

PE PE4_1(.clk(clk),.rst_n(rst_n),.inA(inA41),.inB(outC31),.inW(w_matrix[3][0]),.outC(outC41),.outD(outD41));
PE PE4_2(.clk(clk),.rst_n(rst_n),.inA(outD41),.inB(outC32),.inW(w_matrix[3][1]),.outC(outC42),.outD(outD42));
PE PE4_3(.clk(clk),.rst_n(rst_n),.inA(outD42),.inB(outC33),.inW(w_matrix[3][2]),.outC(outC43),.outD(outD43));
PE PE4_4(.clk(clk),.rst_n(rst_n),.inA(outD43),.inB(outC34),.inW(w_matrix[3][3]),.outC(outC44),.outD(outD44));
PE PE4_5(.clk(clk),.rst_n(rst_n),.inA(outD44),.inB(outC35),.inW(w_matrix[3][4]),.outC(outC45),.outD(outD45));
PE PE4_6(.clk(clk),.rst_n(rst_n),.inA(outD45),.inB(outC36),.inW(w_matrix[3][5]),.outC(outC46),.outD(outD46));
PE PE4_7(.clk(clk),.rst_n(rst_n),.inA(outD46),.inB(outC37),.inW(w_matrix[3][6]),.outC(outC47),.outD(outD47));
PE PE4_8(.clk(clk),.rst_n(rst_n),.inA(outD47),.inB(outC38),.inW(w_matrix[3][7]),.outC(outC48),.outD(outD48));

PE PE5_1(.clk(clk),.rst_n(rst_n),.inA (inA51),.inB(outC41),.inW(w_matrix[4][0]),.outC(outC51),.outD(outD51));
PE PE5_2(.clk(clk),.rst_n(rst_n),.inA(outD51),.inB(outC42),.inW(w_matrix[4][1]),.outC(outC52),.outD(outD52));
PE PE5_3(.clk(clk),.rst_n(rst_n),.inA(outD52),.inB(outC43),.inW(w_matrix[4][2]),.outC(outC53),.outD(outD53));
PE PE5_4(.clk(clk),.rst_n(rst_n),.inA(outD53),.inB(outC44),.inW(w_matrix[4][3]),.outC(outC54),.outD(outD54));
PE PE5_5(.clk(clk),.rst_n(rst_n),.inA(outD54),.inB(outC45),.inW(w_matrix[4][4]),.outC(outC55),.outD(outD55));
PE PE5_6(.clk(clk),.rst_n(rst_n),.inA(outD55),.inB(outC46),.inW(w_matrix[4][5]),.outC(outC56),.outD(outD56));
PE PE5_7(.clk(clk),.rst_n(rst_n),.inA(outD56),.inB(outC47),.inW(w_matrix[4][6]),.outC(outC57),.outD(outD57));
PE PE5_8(.clk(clk),.rst_n(rst_n),.inA(outD57),.inB(outC48),.inW(w_matrix[4][7]),.outC(outC58),.outD(outD58));

PE PE6_1(.clk(clk),.rst_n(rst_n),.inA (inA61),.inB(outC51),.inW(w_matrix[5][0]),.outC(outC61),.outD(outD61));
PE PE6_2(.clk(clk),.rst_n(rst_n),.inA(outD61),.inB(outC52),.inW(w_matrix[5][1]),.outC(outC62),.outD(outD62));
PE PE6_3(.clk(clk),.rst_n(rst_n),.inA(outD62),.inB(outC53),.inW(w_matrix[5][2]),.outC(outC63),.outD(outD63));
PE PE6_4(.clk(clk),.rst_n(rst_n),.inA(outD63),.inB(outC54),.inW(w_matrix[5][3]),.outC(outC64),.outD(outD64));
PE PE6_5(.clk(clk),.rst_n(rst_n),.inA(outD64),.inB(outC55),.inW(w_matrix[5][4]),.outC(outC65),.outD(outD65));
PE PE6_6(.clk(clk),.rst_n(rst_n),.inA(outD65),.inB(outC56),.inW(w_matrix[5][5]),.outC(outC66),.outD(outD66));
PE PE6_7(.clk(clk),.rst_n(rst_n),.inA(outD66),.inB(outC57),.inW(w_matrix[5][6]),.outC(outC67),.outD(outD67));
PE PE6_8(.clk(clk),.rst_n(rst_n),.inA(outD67),.inB(outC58),.inW(w_matrix[5][7]),.outC(outC68),.outD(outD68));

PE PE7_1(.clk(clk),.rst_n(rst_n),.inA (inA71),.inB(outC61),.inW(w_matrix[6][0]),.outC(outC71),.outD(outD71));
PE PE7_2(.clk(clk),.rst_n(rst_n),.inA(outD71),.inB(outC62),.inW(w_matrix[6][1]),.outC(outC72),.outD(outD72));
PE PE7_3(.clk(clk),.rst_n(rst_n),.inA(outD72),.inB(outC63),.inW(w_matrix[6][2]),.outC(outC73),.outD(outD73));
PE PE7_4(.clk(clk),.rst_n(rst_n),.inA(outD73),.inB(outC64),.inW(w_matrix[6][3]),.outC(outC74),.outD(outD74));
PE PE7_5(.clk(clk),.rst_n(rst_n),.inA(outD74),.inB(outC65),.inW(w_matrix[6][4]),.outC(outC75),.outD(outD75));
PE PE7_6(.clk(clk),.rst_n(rst_n),.inA(outD75),.inB(outC66),.inW(w_matrix[6][5]),.outC(outC76),.outD(outD76));
PE PE7_7(.clk(clk),.rst_n(rst_n),.inA(outD76),.inB(outC67),.inW(w_matrix[6][6]),.outC(outC77),.outD(outD77));
PE PE7_8(.clk(clk),.rst_n(rst_n),.inA(outD77),.inB(outC68),.inW(w_matrix[6][7]),.outC(outC78),.outD(outD78));

PE PE8_1(.clk(clk),.rst_n(rst_n),.inA (inA81),.inB(outC71),.inW(w_matrix[7][0]),.outC(outC81),.outD(outD81));
PE PE8_2(.clk(clk),.rst_n(rst_n),.inA(outD81),.inB(outC72),.inW(w_matrix[7][1]),.outC(outC82),.outD(outD82));
PE PE8_3(.clk(clk),.rst_n(rst_n),.inA(outD82),.inB(outC73),.inW(w_matrix[7][2]),.outC(outC83),.outD(outD83));
PE PE8_4(.clk(clk),.rst_n(rst_n),.inA(outD83),.inB(outC74),.inW(w_matrix[7][3]),.outC(outC84),.outD(outD84));
PE PE8_5(.clk(clk),.rst_n(rst_n),.inA(outD84),.inB(outC75),.inW(w_matrix[7][4]),.outC(outC85),.outD(outD85));
PE PE8_6(.clk(clk),.rst_n(rst_n),.inA(outD85),.inB(outC76),.inW(w_matrix[7][5]),.outC(outC86),.outD(outD86));
PE PE8_7(.clk(clk),.rst_n(rst_n),.inA(outD86),.inB(outC77),.inW(w_matrix[7][6]),.outC(outC87),.outD(outD87));
PE PE8_8(.clk(clk),.rst_n(rst_n),.inA(outD87),.inB(outC78),.inW(w_matrix[7][7]),.outC(outC88),.outD(outD88));



//assign c_plus = (m_size==2'b00) ? outC21+outC22 :
//                (m_size==2'b01) ? outC41+outC42+outC43+outC44 : 
//                (m_size==2'b10) ? outC81+outC82+outC83+outC84+outC85+outC86+outC87+outC88 : 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        c_plus <= 'd0;
    end
    else if(cs==CAL) begin
        case(m_size)
            2'b00 : c_plus <= outC21+outC22;
            2'b01 : c_plus <= outC41+outC42+outC43+outC44;
            2'b10 : c_plus <= outC81+outC82+outC83+outC84+outC85+outC86+outC87+outC88;
            default : c_plus <= 'd0;
        endcase
    end
    else begin
        c_plus <= 'd0;
    end
end

always @(*) begin
    casez(c_plus)
        40'b1???_????_????_????_????_????_????_????_????_???? : length <= 6'd40;
        40'b01??_????_????_????_????_????_????_????_????_???? : length <= 6'd39;
        40'b001?_????_????_????_????_????_????_????_????_???? : length <= 6'd38;
        40'b0001_????_????_????_????_????_????_????_????_???? : length <= 6'd37;
        40'b0000_1???_????_????_????_????_????_????_????_???? : length <= 6'd36;
        40'b0000_01??_????_????_????_????_????_????_????_???? : length <= 6'd35;
        40'b0000_001?_????_????_????_????_????_????_????_???? : length <= 6'd34;
        40'b0000_0001_????_????_????_????_????_????_????_???? : length <= 6'd33;
        40'b0000_0000_1???_????_????_????_????_????_????_???? : length <= 6'd32;
        40'b0000_0000_01??_????_????_????_????_????_????_???? : length <= 6'd31;
        40'b0000_0000_001?_????_????_????_????_????_????_???? : length <= 6'd30;
        40'b0000_0000_0001_????_????_????_????_????_????_???? : length <= 6'd29;
        40'b0000_0000_0000_1???_????_????_????_????_????_???? : length <= 6'd28;
        40'b0000_0000_0000_01??_????_????_????_????_????_???? : length <= 6'd27;
        40'b0000_0000_0000_001?_????_????_????_????_????_???? : length <= 6'd26;
        40'b0000_0000_0000_0001_????_????_????_????_????_???? : length <= 6'd25;
        40'b0000_0000_0000_0000_1???_????_????_????_????_???? : length <= 6'd24;
        40'b0000_0000_0000_0000_01??_????_????_????_????_???? : length <= 6'd23;
        40'b0000_0000_0000_0000_001?_????_????_????_????_???? : length <= 6'd22;
        40'b0000_0000_0000_0000_0001_????_????_????_????_???? : length <= 6'd21;
        40'b0000_0000_0000_0000_0000_1???_????_????_????_???? : length <= 6'd20;
        40'b0000_0000_0000_0000_0000_01??_????_????_????_???? : length <= 6'd19;
        40'b0000_0000_0000_0000_0000_001?_????_????_????_???? : length <= 6'd18;
        40'b0000_0000_0000_0000_0000_0001_????_????_????_???? : length <= 6'd17;
        40'b0000_0000_0000_0000_0000_0000_1???_????_????_???? : length <= 6'd16;
        40'b0000_0000_0000_0000_0000_0000_01??_????_????_???? : length <= 6'd15;
        40'b0000_0000_0000_0000_0000_0000_001?_????_????_???? : length <= 6'd14;
        40'b0000_0000_0000_0000_0000_0000_0001_????_????_???? : length <= 6'd13;
        40'b0000_0000_0000_0000_0000_0000_0000_1???_????_???? : length <= 6'd12;
        40'b0000_0000_0000_0000_0000_0000_0000_01??_????_???? : length <= 6'd11;
        40'b0000_0000_0000_0000_0000_0000_0000_001?_????_???? : length <= 6'd10;
        40'b0000_0000_0000_0000_0000_0000_0000_0001_????_???? : length <= 6'd9;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_1???_???? : length <= 6'd8;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_01??_???? : length <= 6'd7;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_001?_???? : length <= 6'd6;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_0001_???? : length <= 6'd5;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_0000_1??? : length <= 6'd4;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_0000_01?? : length <= 6'd3;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_0000_001? : length <= 6'd2;
        40'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0001 : length <= 6'd1;
        default : length <= 6'd0;
    endcase
end

integer m,n;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (m = 0; m < 15; m=m+1) begin
            cal_out[m] <= 'd0;
        end
    end
    else if(cs==CAL) begin
        cal_out[store_cnt] <= c_plus;
    end
    else if(cs==IDLE) begin
        for (m = 0; m < 15; m=m+1) begin
            cal_out[m] <= 'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (n = 0; n < 15; n=n+1) begin
            length_reg[n] <= 'd0;
        end
    end
    else if(cs==CAL) begin
        length_reg[store_cnt] <= length;
    end
    else if(cs==IDLE)begin
        for (n = 0; n < 15; n=n+1) begin
            length_reg[n] <= 'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        store_cnt <= 'd0;
    end
    else if(cs==CAL && cal_cnt>calout_cnt)begin
        store_cnt <= store_cnt + 'd1;
    end
    else begin
        store_cnt <= 'd0;
    end
end




//==============================================//
//              OUTPUT Block                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         out_value <= 'd0;
    end
    else if(cs == OUTPUT)begin
        if(length_value_flag) begin //length:0 value:1
            out_value <= value_out[out_cnt];
        end
        else begin
            out_value <= length_out[5-out_cnt_6];
        end
    end
    else begin
         out_value <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        out_valid <= 'd0;
    else if(cs==OUTPUT) 
        out_valid <= 'd1;
    else 
        out_valid <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_cnt_6 <= 7;
    end
    else if(ns==OUTPUT)begin
        if(out_cnt_6==5)    out_cnt_6 <= 7;
        else if(out_cnt==0) out_cnt_6 <= out_cnt_6 + 'd1;
    end
    else begin
        out_cnt_6 <= 7;
    end
end

assign length_value_flag = (out_cnt_6 == 7 ) ? 1 : 0; 

assign length_out = length_reg[outset_cnt];
assign value_out = cal_out[outset_cnt];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_cnt <= 'd0;
    end
    else if(ns==OUTPUT) begin
        if(out_cnt_6==5)begin
            out_cnt <= length_out-1;
        end
        else if(out_cnt==0) out_cnt <= 0;
        else begin
            out_cnt <= out_cnt - 'd1;
        end
    end
    else begin
        out_cnt <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        outset_cnt <= 0;
    end
    else if(cs==OUTPUT)begin
        if(out_cnt==0 && out_cnt_6==7)
            outset_cnt <= outset_cnt + 'd1;
    end
    else begin
        outset_cnt <= 0;
    end
end


/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         <= 'd0;
    end
    else begin
         <= 'd0;
    end
end

always @(*) begin
    if () begin
         = 'd0;
    end
    else begin
         = 'd0;
    end
end

*/

/*
genvar i;
generate
for(i=0;i<256;i=i+1) begin: name
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            
        end
        else begin
            
        end
    end
end
endgenerate
*/

endmodule


module PE(rst_n,clk,inA,inB,inW,outC,outD);

input rst_n,clk;
input signed [39:0] inB;
input signed [15:0] inA,inW;
output reg signed [39:0] outC;
output reg signed [15:0] outD;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         outC <= 'd0;
    end
    else begin
         outC <= inA*inW +inB;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         outD <= 'd0;
    end
    else begin
         outD <= inA;
    end
end

endmodule


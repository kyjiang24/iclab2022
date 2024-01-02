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
input [15:0] matrix;
input [1:0]  matrix_size;
input [3:0]  i_mat_idx, w_mat_idx;

output reg               out_valid;
output reg signed [39:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter IDLE      =   3'd0;
parameter INPUT_0   =   3'd1;
parameter INPUT_1   =   3'd2;
parameter EMPTY     =   3'd6;
parameter INPUT_2   =   3'd3;
parameter CAL_IN    =   3'd4;
parameter CAL       =   3'd5;
//parameter OUTPUT    =   3'd6;


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [2:0] ns,cs;
reg [1:0] m_size;//4
reg [7:0] m_element; //256
reg [6:0] mem_num; //128
reg [5:0] calout_num; //64
reg [63:0] in_64;
reg [1:0] in_cnt_4;
reg [9:0] in_addr_cnt;
reg [4:0] in_matrix_cnt; //32
reg [7:0] in_cnt;
wire [63:0] mem_in_Q,mem_weight_Q;
wire [9:0] mem_in_A,mem_weight_A;

wire wen_in,wen_weight;
wire flag;
reg in_weight_flag;

wire [9:0] in_start_addr,weight_start_addr; //1024
reg [9:0] calin_addr,calweight_addr; //1024
reg [7:0] calin_cnt; //256
reg [7:0] cal_cnt;
reg [4:0] out_cycle,out_cnt; //32
reg [4:0] calout_cnt; //32

wire [3:0] x_addr,y_addr; //16

reg signed[15:0] x_matrix[0:15][0:15];
reg signed[15:0] w_matrix[0:15][0:15];

reg signed [15:0] inA11,inA21,inA31,inA41,inA51,inA61,inA71,inA81,inA91,inA10_1,inA11_1,inA12_1,inA13_1,inA14_1,inA15_1,inA16_1;

wire signed [39:0] outC11,outC21,outC31,outC41,outC51,outC61,outC71,outC81,outC91,outC10_1,outC11_1,outC12_1,outC13_1,outC14_1,outC15_1,outC16_1;
wire signed [39:0] outC12,outC22,outC32,outC42,outC52,outC62,outC72,outC82,outC92,outC10_2,outC11_2,outC12_2,outC13_2,outC14_2,outC15_2,outC16_2;
wire signed [39:0] outC13,outC23,outC33,outC43,outC53,outC63,outC73,outC83,outC93,outC10_3,outC11_3,outC12_3,outC13_3,outC14_3,outC15_3,outC16_3;
wire signed [39:0] outC14,outC24,outC34,outC44,outC54,outC64,outC74,outC84,outC94,outC10_4,outC11_4,outC12_4,outC13_4,outC14_4,outC15_4,outC16_4;
wire signed [39:0] outC15,outC25,outC35,outC45,outC55,outC65,outC75,outC85,outC95,outC10_5,outC11_5,outC12_5,outC13_5,outC14_5,outC15_5,outC16_5;
wire signed [39:0] outC16,outC26,outC36,outC46,outC56,outC66,outC76,outC86,outC96,outC10_6,outC11_6,outC12_6,outC13_6,outC14_6,outC15_6,outC16_6;
wire signed [39:0] outC17,outC27,outC37,outC47,outC57,outC67,outC77,outC87,outC97,outC10_7,outC11_7,outC12_7,outC13_7,outC14_7,outC15_7,outC16_7;
wire signed [39:0] outC18,outC28,outC38,outC48,outC58,outC68,outC78,outC88,outC98,outC10_8,outC11_8,outC12_8,outC13_8,outC14_8,outC15_8,outC16_8;
wire signed [39:0] outC19,outC29,outC39,outC49,outC59,outC69,outC79,outC89,outC99,outC10_9,outC11_9,outC12_9,outC13_9,outC14_9,outC15_9,outC16_9;
wire signed [39:0] outC1_10,outC2_10,outC3_10,outC4_10,outC5_10,outC6_10,outC7_10,outC8_10,outC9_10,outC10_10,outC11_10,outC12_10,outC13_10,outC14_10,outC15_10,outC16_10;
wire signed [39:0] outC1_11,outC2_11,outC3_11,outC4_11,outC5_11,outC6_11,outC7_11,outC8_11,outC9_11,outC10_11,outC11_11,outC12_11,outC13_11,outC14_11,outC15_11,outC16_11;
wire signed [39:0] outC1_12,outC2_12,outC3_12,outC4_12,outC5_12,outC6_12,outC7_12,outC8_12,outC9_12,outC10_12,outC11_12,outC12_12,outC13_12,outC14_12,outC15_12,outC16_12;
wire signed [39:0] outC1_13,outC2_13,outC3_13,outC4_13,outC5_13,outC6_13,outC7_13,outC8_13,outC9_13,outC10_13,outC11_13,outC12_13,outC13_13,outC14_13,outC15_13,outC16_13;
wire signed [39:0] outC1_14,outC2_14,outC3_14,outC4_14,outC5_14,outC6_14,outC7_14,outC8_14,outC9_14,outC10_14,outC11_14,outC12_14,outC13_14,outC14_14,outC15_14,outC16_14;
wire signed [39:0] outC1_15,outC2_15,outC3_15,outC4_15,outC5_15,outC6_15,outC7_15,outC8_15,outC9_15,outC10_15,outC11_15,outC12_15,outC13_15,outC14_15,outC15_15,outC16_15;
wire signed [39:0] outC1_16,outC2_16,outC3_16,outC4_16,outC5_16,outC6_16,outC7_16,outC8_16,outC9_16,outC10_16,outC11_16,outC12_16,outC13_16,outC14_16,outC15_16,outC16_16;

wire signed [15:0] outD11,outD21,outD31,outD41,outD51,outD61,outD71,outD81,outD91,outD10_1,outD11_1,outD12_1,outD13_1,outD14_1,outD15_1,outD16_1;
wire signed [15:0] outD12,outD22,outD32,outD42,outD52,outD62,outD72,outD82,outD92,outD10_2,outD11_2,outD12_2,outD13_2,outD14_2,outD15_2,outD16_2;
wire signed [15:0] outD13,outD23,outD33,outD43,outD53,outD63,outD73,outD83,outD93,outD10_3,outD11_3,outD12_3,outD13_3,outD14_3,outD15_3,outD16_3;
wire signed [15:0] outD14,outD24,outD34,outD44,outD54,outD64,outD74,outD84,outD94,outD10_4,outD11_4,outD12_4,outD13_4,outD14_4,outD15_4,outD16_4;
wire signed [15:0] outD15,outD25,outD35,outD45,outD55,outD65,outD75,outD85,outD95,outD10_5,outD11_5,outD12_5,outD13_5,outD14_5,outD15_5,outD16_5;
wire signed [15:0] outD16,outD26,outD36,outD46,outD56,outD66,outD76,outD86,outD96,outD10_6,outD11_6,outD12_6,outD13_6,outD14_6,outD15_6,outD16_6;
wire signed [15:0] outD17,outD27,outD37,outD47,outD57,outD67,outD77,outD87,outD97,outD10_7,outD11_7,outD12_7,outD13_7,outD14_7,outD15_7,outD16_7;
wire signed [15:0] outD18,outD28,outD38,outD48,outD58,outD68,outD78,outD88,outD98,outD10_8,outD11_8,outD12_8,outD13_8,outD14_8,outD15_8,outD16_8;
wire signed [15:0] outD19,outD29,outD39,outD49,outD59,outD69,outD79,outD89,outD99,outD10_9,outD11_9,outD12_9,outD13_9,outD14_9,outD15_9,outD16_9;
wire signed [15:0] outD1_10,outD2_10,outD3_10,outD4_10,outD5_10,outD6_10,outD7_10,outD8_10,outD9_10,outD10_10,outD11_10,outD12_10,outD13_10,outD14_10,outD15_10,outD16_10;
wire signed [15:0] outD1_11,outD2_11,outD3_11,outD4_11,outD5_11,outD6_11,outD7_11,outD8_11,outD9_11,outD10_11,outD11_11,outD12_11,outD13_11,outD14_11,outD15_11,outD16_11;
wire signed [15:0] outD1_12,outD2_12,outD3_12,outD4_12,outD5_12,outD6_12,outD7_12,outD8_12,outD9_12,outD10_12,outD11_12,outD12_12,outD13_12,outD14_12,outD15_12,outD16_12;
wire signed [15:0] outD1_13,outD2_13,outD3_13,outD4_13,outD5_13,outD6_13,outD7_13,outD8_13,outD9_13,outD10_13,outD11_13,outD12_13,outD13_13,outD14_13,outD15_13,outD16_13;
wire signed [15:0] outD1_14,outD2_14,outD3_14,outD4_14,outD5_14,outD6_14,outD7_14,outD8_14,outD9_14,outD10_14,outD11_14,outD12_14,outD13_14,outD14_14,outD15_14,outD16_14;
wire signed [15:0] outD1_15,outD2_15,outD3_15,outD4_15,outD5_15,outD6_15,outD7_15,outD8_15,outD9_15,outD10_15,outD11_15,outD12_15,outD13_15,outD14_15,outD15_15,outD16_15;
wire signed [15:0] outD1_16,outD2_16,outD3_16,outD4_16,outD5_16,outD6_16,outD7_16,outD8_16,outD9_16,outD10_16,outD11_16,outD12_16,outD13_16,outD14_16,outD15_16,outD16_16;

wire signed [39:0] c_plus;

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
    EMPTY   : ns = INPUT_2;
    INPUT_2 : ns = CAL_IN;
    CAL_IN  : ns = (calin_cnt==mem_num)? CAL : CAL_IN;
    CAL     : ns = (out_cnt<out_cycle) ? CAL : IDLE;
    //OUTPUT    : ns = IDLE;
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
        2'b00: m_element =  8'd3;
        2'b01: m_element =  8'd15;
        2'b10: m_element =  8'd63;
        2'b11: m_element =  8'd255;
        default: m_element =  8'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: mem_num =  7'd1;
        2'b01: mem_num =  7'd4;
        2'b10: mem_num =  7'd16;
        2'b11: mem_num =  7'd64;
        default: mem_num =  7'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: calout_num =  6'd1;
        2'b01: calout_num =  6'd1;
        2'b10: calout_num =  6'd7;
        2'b11: calout_num =  6'd47;
        default: calout_num =  6'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: calout_cnt =  5'd3;
        2'b01: calout_cnt =  5'd5;
        2'b10: calout_cnt =  5'd9;
        2'b11: calout_cnt =  5'd17;
        default: calout_cnt =  5'd0;
    endcase
end

always @(*) begin
    case(m_size)
        2'b00: out_cycle =  5'd2;
        2'b01: out_cycle =  5'd6;
        2'b10: out_cycle =  5'd14;
        2'b11: out_cycle =  5'd30;
        default: out_cycle =  5'd0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_cnt_4 <= 2'd0;
    end
    else if(in_valid)begin
        in_cnt_4 <= in_cnt_4 + 2'd1 ;
    end
    else begin
        in_cnt_4 <= 2'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_cnt <= 8'd0;
    end
    else if(in_valid)begin
        if(in_cnt == m_element) in_cnt <= 8'd0;
        else    in_cnt <= in_cnt + 8'd1 ;
    end
    else begin
        in_cnt <= 8'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_matrix_cnt <= 5'd0;
    end
    else if(in_cnt == m_element)begin
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
        if(in_cnt_4==2'd0)     in_64 <= matrix;
        else    in_64 <= {in_64[47:0],matrix};
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
        if(in_cnt_4==0) begin
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

assign wen_in = (cs==INPUT_1 && in_cnt_4==0 && ~in_weight_flag) ? 1'b0 : 1'b1 ;
assign wen_weight = (cs==INPUT_1 && in_cnt_4==0 && in_weight_flag) ? 1'b0 : 1'b1 ;

//assign mem_in_A = (cs==INPUT_1) ? in_addr_cnt : (ns==CAL_IN) ? calin_addr  : 0; //can't use ns(combination?)
//assign mem_weight_A = (cs==INPUT_1) ? in_addr_cnt : (ns==CAL_IN) ? calweight_addr : 0;
assign mem_in_A = (cs==INPUT_1) ? in_addr_cnt :  calin_addr ;
assign mem_weight_A = (cs==INPUT_1) ? in_addr_cnt : calweight_addr ;


// 1024 64 4 50
SRAM MEM_IN (.Q(mem_in_Q), .CLK(~clk), .CEN(1'b0), .WEN(wen_in), .A(mem_in_A), .D(in_64), .OEN(1'b0));
SRAM MEM_WEIGHT (.Q(mem_weight_Q), .CLK(~clk), .CEN(1'b0), .WEN(wen_weight), .A(mem_weight_A), .D(in_64), .OEN(1'b0));
//SRAM MEM_IN (.Q(mem_in_Q), .CLK(clk), .CEN(1'b0), .WEN(wen_in), .A(mem_in_A), .D(in_64), .OEN(1'b0));
//SRAM MEM_WEIGHT (.Q(mem_weight_Q), .CLK(clk), .CEN(1'b0), .WEN(wen_weight), .A(mem_weight_A), .D(in_64), .OEN(1'b0));

//==============================================//
//              INPUT_2 Block                   //
//==============================================//

assign in_start_addr = i_mat_idx*mem_num ;
assign weight_start_addr = w_mat_idx*mem_num ;

//==============================================//
//              CAL_IN Block                    //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calin_addr <= 'd0;
    end
    else if(ns == INPUT_2)begin
        calin_addr <= in_start_addr;
    end
    else if(ns == CAL_IN)begin
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
    else if(ns == INPUT_2)begin
        calweight_addr <= weight_start_addr;
    end
    else if(ns == CAL_IN)begin
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
    else if(ns == CAL_IN)begin
        calin_cnt <= calin_cnt + 'd1;
    end
    else begin
        calin_cnt <= 'd0;
    end
end

assign x_addr = (m_size==2'b01) ? 0 :
                (m_size==2'b10) ? (calin_cnt<<2)%8 :
                (m_size==2'b11) ? (calin_cnt<<2)%16 : 0;
assign y_addr = (m_size==2'b01) ? calin_cnt   : 
                (m_size==2'b10) ? calin_cnt>>1 : 
                (m_size==2'b11) ? calin_cnt>>2 : 0;
integer i;
integer j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0;i<16;i=i+1)
            for(j=0;j<16;j=j+1)
                x_matrix[i][j] <= 'd0;
    end
    else if(ns == CAL_IN)begin
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
        for(i=0;i<16;i=i+1)
            for(j=0;j<16;j=j+1)
                x_matrix[i][j] <= 'd0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0;i<16;i=i+1)
            for(j=0;j<16;j=j+1)
                w_matrix[i][j] <= 'd0;
    end
    else if(ns == CAL_IN)begin
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
        for(i=0;i<16;i=i+1)
            for(j=0;j<16;j=j+1)
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
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
    else if(calin_cnt>calout_num || ns == CAL)begin
        case(cal_cnt)
            6'd0:  inA11 <= x_matrix[0 ][0];
            6'd1:  inA11 <= x_matrix[1 ][0];
            6'd2:  inA11 <= x_matrix[2 ][0];
            6'd3:  inA11 <= x_matrix[3 ][0];
            6'd4:  inA11 <= x_matrix[4 ][0];
            6'd5:  inA11 <= x_matrix[5 ][0];
            6'd6:  inA11 <= x_matrix[6 ][0];
            6'd7:  inA11 <= x_matrix[7 ][0];
            6'd8 : inA11 <= x_matrix[8 ][0];
            6'd9 : inA11 <= x_matrix[9 ][0];
            6'd10: inA11 <= x_matrix[10][0];
            6'd11: inA11 <= x_matrix[11][0];
            6'd12: inA11 <= x_matrix[12][0];
            6'd13: inA11 <= x_matrix[13][0];
            6'd14: inA11 <= x_matrix[14][0];
            6'd15: inA11 <= x_matrix[15][0];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd1:  inA21 <= x_matrix[0][1];
            6'd2:  inA21 <= x_matrix[1][1];
            6'd3:  inA21 <= x_matrix[2][1];
            6'd4:  inA21 <= x_matrix[3][1];
            6'd5:  inA21 <= x_matrix[4][1];
            6'd6:  inA21 <= x_matrix[5][1];
            6'd7:  inA21 <= x_matrix[6][1];
            6'd8 : inA21 <= x_matrix[7][1];
            6'd9 : inA21 <= x_matrix[8 ][1];
            6'd10: inA21 <= x_matrix[9 ][1];
            6'd11: inA21 <= x_matrix[10][1];
            6'd12: inA21 <= x_matrix[11][1];
            6'd13: inA21 <= x_matrix[12][1];
            6'd14: inA21 <= x_matrix[13][1];
            6'd15: inA21 <= x_matrix[14][1];
            6'd16: inA21 <= x_matrix[15][1];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd2:  inA31 <= x_matrix[0][2];
            6'd3:  inA31 <= x_matrix[1][2];
            6'd4:  inA31 <= x_matrix[2][2];
            6'd5:  inA31 <= x_matrix[3][2];
            6'd6:  inA31 <= x_matrix[4][2];
            6'd7:  inA31 <= x_matrix[5][2];
            6'd8:  inA31 <= x_matrix[6][2];
            6'd9:  inA31 <= x_matrix[7][2];
            6'd10: inA31 <= x_matrix[8 ][2];
            6'd11: inA31 <= x_matrix[9 ][2];
            6'd12: inA31 <= x_matrix[10][2];
            6'd13: inA31 <= x_matrix[11][2];
            6'd14: inA31 <= x_matrix[12][2];
            6'd15: inA31 <= x_matrix[13][2];
            6'd16: inA31 <= x_matrix[14][2];
            6'd17: inA31 <= x_matrix[15][2];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd3 :  inA41 <= x_matrix[0][3];
            6'd4 :  inA41 <= x_matrix[1][3];
            6'd5 :  inA41 <= x_matrix[2][3];
            6'd6 :  inA41 <= x_matrix[3][3];
            6'd7 :  inA41 <= x_matrix[4][3];
            6'd8 :  inA41 <= x_matrix[5][3];
            6'd9 :  inA41 <= x_matrix[6][3];
            6'd10:  inA41 <= x_matrix[7][3];
            6'd11: inA41 <= x_matrix[8 ][3];
            6'd12: inA41 <= x_matrix[9 ][3];
            6'd13: inA41 <= x_matrix[10][3];
            6'd14: inA41 <= x_matrix[11][3];
            6'd15: inA41 <= x_matrix[12][3];
            6'd16: inA41 <= x_matrix[13][3];
            6'd17: inA41 <= x_matrix[14][3];
            6'd18: inA41 <= x_matrix[15][3];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd4 :  inA51 <= x_matrix[0][4];
            6'd5 :  inA51 <= x_matrix[1][4];
            6'd6 :  inA51 <= x_matrix[2][4];
            6'd7 :  inA51 <= x_matrix[3][4];
            6'd8 :  inA51 <= x_matrix[4][4];
            6'd9 :  inA51 <= x_matrix[5][4];
            6'd10:  inA51 <= x_matrix[6][4];
            6'd11:  inA51 <= x_matrix[7][4];
            6'd12: inA51 <= x_matrix[8 ][4];
            6'd13: inA51 <= x_matrix[9 ][4];
            6'd14: inA51 <= x_matrix[10][4];
            6'd15: inA51 <= x_matrix[11][4];
            6'd16: inA51 <= x_matrix[12][4];
            6'd17: inA51 <= x_matrix[13][4];
            6'd18: inA51 <= x_matrix[14][4];
            6'd19: inA51 <= x_matrix[15][4];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd5 :  inA61 <= x_matrix[0][5];
            6'd6 :  inA61 <= x_matrix[1][5];
            6'd7 :  inA61 <= x_matrix[2][5];
            6'd8 :  inA61 <= x_matrix[3][5];
            6'd9 :  inA61 <= x_matrix[4][5];
            6'd10:  inA61 <= x_matrix[5][5];
            6'd11:  inA61 <= x_matrix[6][5];
            6'd12:  inA61 <= x_matrix[7][5];
            6'd13: inA61 <= x_matrix[8 ][5];
            6'd14: inA61 <= x_matrix[9 ][5];
            6'd15: inA61 <= x_matrix[10][5];
            6'd16: inA61 <= x_matrix[11][5];
            6'd17: inA61 <= x_matrix[12][5];
            6'd18: inA61 <= x_matrix[13][5];
            6'd19: inA61 <= x_matrix[14][5];
            6'd20: inA61 <= x_matrix[15][5];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd6 :  inA71 <= x_matrix[0][6];
            6'd7 :  inA71 <= x_matrix[1][6];
            6'd8 :  inA71 <= x_matrix[2][6];
            6'd9 :  inA71 <= x_matrix[3][6];
            6'd10:  inA71 <= x_matrix[4][6];
            6'd11:  inA71 <= x_matrix[5][6];
            6'd12:  inA71 <= x_matrix[6][6];
            6'd13:  inA71 <= x_matrix[7][6];
            6'd14: inA71 <= x_matrix[8 ][6];
            6'd15: inA71 <= x_matrix[9 ][6];
            6'd16: inA71 <= x_matrix[10][6];
            6'd17: inA71 <= x_matrix[11][6];
            6'd18: inA71 <= x_matrix[12][6];
            6'd19: inA71 <= x_matrix[13][6];
            6'd20: inA71 <= x_matrix[14][6];
            6'd21: inA71 <= x_matrix[15][6];
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
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd7 :  inA81 <= x_matrix[0 ][7];
            6'd8 :  inA81 <= x_matrix[1 ][7];
            6'd9 :  inA81 <= x_matrix[2 ][7];
            6'd10:  inA81 <= x_matrix[3 ][7];
            6'd11:  inA81 <= x_matrix[4 ][7];
            6'd12:  inA81 <= x_matrix[5 ][7];
            6'd13:  inA81 <= x_matrix[6 ][7];
            6'd14:  inA81 <= x_matrix[7 ][7];
            6'd15:  inA81 <= x_matrix[8 ][7];
            6'd16:  inA81 <= x_matrix[9 ][7];
            6'd17:  inA81 <= x_matrix[10][7];
            6'd18:  inA81 <= x_matrix[11][7];
            6'd19:  inA81 <= x_matrix[12][7];
            6'd20:  inA81 <= x_matrix[13][7];
            6'd21:  inA81 <= x_matrix[14][7];
            6'd22:  inA81 <= x_matrix[15][7];
            default:inA81 <= 'd0;
        endcase
    end
    else begin
        inA81 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA91 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd8 :  inA91 <= x_matrix[0 ][8];
            6'd9 :  inA91 <= x_matrix[1 ][8];
            6'd10:  inA91 <= x_matrix[2 ][8];
            6'd11:  inA91 <= x_matrix[3 ][8];
            6'd12:  inA91 <= x_matrix[4 ][8];
            6'd13:  inA91 <= x_matrix[5 ][8];
            6'd14:  inA91 <= x_matrix[6 ][8];
            6'd15:  inA91 <= x_matrix[7 ][8];
            6'd16:  inA91 <= x_matrix[8 ][8];
            6'd17:  inA91 <= x_matrix[9 ][8];
            6'd18:  inA91 <= x_matrix[10][8];
            6'd19:  inA91 <= x_matrix[11][8];
            6'd20:  inA91 <= x_matrix[12][8];
            6'd21:  inA91 <= x_matrix[13][8];
            6'd22:  inA91 <= x_matrix[14][8];
            6'd23:  inA91 <= x_matrix[15][8];
            default:inA91 <= 'd0;
        endcase
    end
    else begin
        inA91 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA10_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd9 :  inA10_1 <= x_matrix[0 ][9];
            6'd10:  inA10_1 <= x_matrix[1 ][9];
            6'd11:  inA10_1 <= x_matrix[2 ][9];
            6'd12:  inA10_1 <= x_matrix[3 ][9];
            6'd13:  inA10_1 <= x_matrix[4 ][9];
            6'd14:  inA10_1 <= x_matrix[5 ][9];
            6'd15:  inA10_1 <= x_matrix[6 ][9];
            6'd16:  inA10_1 <= x_matrix[7 ][9];
            6'd17:  inA10_1 <= x_matrix[8 ][9];
            6'd18:  inA10_1 <= x_matrix[9 ][9];
            6'd19:  inA10_1 <= x_matrix[10][9];
            6'd20:  inA10_1 <= x_matrix[11][9];
            6'd21:  inA10_1 <= x_matrix[12][9];
            6'd22:  inA10_1 <= x_matrix[13][9];
            6'd23:  inA10_1 <= x_matrix[14][9];
            6'd24:  inA10_1 <= x_matrix[15][9];
            default:inA10_1 <= 'd0;
        endcase
    end
    else begin
        inA10_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA11_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd10:  inA11_1 <= x_matrix[0 ][10];
            6'd11:  inA11_1 <= x_matrix[1 ][10];
            6'd12:  inA11_1 <= x_matrix[2 ][10];
            6'd13:  inA11_1 <= x_matrix[3 ][10];
            6'd14:  inA11_1 <= x_matrix[4 ][10];
            6'd15:  inA11_1 <= x_matrix[5 ][10];
            6'd16:  inA11_1 <= x_matrix[6 ][10];
            6'd17:  inA11_1 <= x_matrix[7 ][10];
            6'd18:  inA11_1 <= x_matrix[8 ][10];
            6'd19:  inA11_1 <= x_matrix[9 ][10];
            6'd20:  inA11_1 <= x_matrix[10][10];
            6'd21:  inA11_1 <= x_matrix[11][10];
            6'd22:  inA11_1 <= x_matrix[12][10];
            6'd23:  inA11_1 <= x_matrix[13][10];
            6'd24:  inA11_1 <= x_matrix[14][10];
            6'd25:  inA11_1 <= x_matrix[15][10];
            default:inA11_1 <= 'd0;
        endcase
    end
    else begin
        inA11_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA12_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd11:  inA12_1 <= x_matrix[0 ][11];
            6'd12:  inA12_1 <= x_matrix[1 ][11];
            6'd13:  inA12_1 <= x_matrix[2 ][11];
            6'd14:  inA12_1 <= x_matrix[3 ][11];
            6'd15:  inA12_1 <= x_matrix[4 ][11];
            6'd16:  inA12_1 <= x_matrix[5 ][11];
            6'd17:  inA12_1 <= x_matrix[6 ][11];
            6'd18:  inA12_1 <= x_matrix[7 ][11];
            6'd19:  inA12_1 <= x_matrix[8 ][11];
            6'd20:  inA12_1 <= x_matrix[9 ][11];
            6'd21:  inA12_1 <= x_matrix[10][11];
            6'd22:  inA12_1 <= x_matrix[11][11];
            6'd23:  inA12_1 <= x_matrix[12][11];
            6'd24:  inA12_1 <= x_matrix[13][11];
            6'd25:  inA12_1 <= x_matrix[14][11];
            6'd26:  inA12_1 <= x_matrix[15][11];
            default:inA12_1 <= 'd0;
        endcase
    end
    else begin
        inA12_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA13_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd12:  inA13_1 <= x_matrix[0 ][12];
            6'd13:  inA13_1 <= x_matrix[1 ][12];
            6'd14:  inA13_1 <= x_matrix[2 ][12];
            6'd15:  inA13_1 <= x_matrix[3 ][12];
            6'd16:  inA13_1 <= x_matrix[4 ][12];
            6'd17:  inA13_1 <= x_matrix[5 ][12];
            6'd18:  inA13_1 <= x_matrix[6 ][12];
            6'd19:  inA13_1 <= x_matrix[7 ][12];
            6'd20:  inA13_1 <= x_matrix[8 ][12];
            6'd21:  inA13_1 <= x_matrix[9 ][12];
            6'd22:  inA13_1 <= x_matrix[10][12];
            6'd23:  inA13_1 <= x_matrix[11][12];
            6'd24:  inA13_1 <= x_matrix[12][12];
            6'd25:  inA13_1 <= x_matrix[13][12];
            6'd26:  inA13_1 <= x_matrix[14][12];
            6'd27:  inA13_1 <= x_matrix[15][12];
            default:inA13_1 <= 'd0;
        endcase
    end
    else begin
        inA13_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA14_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd13:  inA14_1 <= x_matrix[0 ][13];
            6'd14:  inA14_1 <= x_matrix[1 ][13];
            6'd15:  inA14_1 <= x_matrix[2 ][13];
            6'd16:  inA14_1 <= x_matrix[3 ][13];
            6'd17:  inA14_1 <= x_matrix[4 ][13];
            6'd18:  inA14_1 <= x_matrix[5 ][13];
            6'd19:  inA14_1 <= x_matrix[6 ][13];
            6'd20:  inA14_1 <= x_matrix[7 ][13];
            6'd21:  inA14_1 <= x_matrix[8 ][13];
            6'd22:  inA14_1 <= x_matrix[9 ][13];
            6'd23:  inA14_1 <= x_matrix[10][13];
            6'd24:  inA14_1 <= x_matrix[11][13];
            6'd25:  inA14_1 <= x_matrix[12][13];
            6'd26:  inA14_1 <= x_matrix[13][13];
            6'd27:  inA14_1 <= x_matrix[14][13];
            6'd28:  inA14_1 <= x_matrix[15][13];
            default:inA14_1 <= 'd0;
        endcase
    end
    else begin
        inA14_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA15_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd14:  inA15_1 <= x_matrix[0 ][14];
            6'd15:  inA15_1 <= x_matrix[1 ][14];
            6'd16:  inA15_1 <= x_matrix[2 ][14];
            6'd17:  inA15_1 <= x_matrix[3 ][14];
            6'd18:  inA15_1 <= x_matrix[4 ][14];
            6'd19:  inA15_1 <= x_matrix[5 ][14];
            6'd20:  inA15_1 <= x_matrix[6 ][14];
            6'd21:  inA15_1 <= x_matrix[7 ][14];
            6'd22:  inA15_1 <= x_matrix[8 ][14];
            6'd23:  inA15_1 <= x_matrix[9 ][14];
            6'd24:  inA15_1 <= x_matrix[10][14];
            6'd25:  inA15_1 <= x_matrix[11][14];
            6'd26:  inA15_1 <= x_matrix[12][14];
            6'd27:  inA15_1 <= x_matrix[13][14];
            6'd28:  inA15_1 <= x_matrix[14][14];
            6'd29:  inA15_1 <= x_matrix[15][14];
            default:inA15_1 <= 'd0;
        endcase
    end
    else begin
        inA15_1 <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        inA16_1 <= 'd0;
    end
    else if(calin_cnt>calout_num ||ns == CAL)begin
        case(cal_cnt)
            6'd15:  inA16_1 <= x_matrix[0 ][15];
            6'd16:  inA16_1 <= x_matrix[1 ][15];
            6'd17:  inA16_1 <= x_matrix[2 ][15];
            6'd18:  inA16_1 <= x_matrix[3 ][15];
            6'd19:  inA16_1 <= x_matrix[4 ][15];
            6'd20:  inA16_1 <= x_matrix[5 ][15];
            6'd21:  inA16_1 <= x_matrix[6 ][15];
            6'd22:  inA16_1 <= x_matrix[7 ][15];
            6'd23:  inA16_1 <= x_matrix[8 ][15];
            6'd24:  inA16_1 <= x_matrix[9 ][15];
            6'd25:  inA16_1 <= x_matrix[10][15];
            6'd26:  inA16_1 <= x_matrix[11][15];
            6'd27:  inA16_1 <= x_matrix[12][15];
            6'd28:  inA16_1 <= x_matrix[13][15];
            6'd29:  inA16_1 <= x_matrix[14][15];
            6'd30:  inA16_1 <= x_matrix[15][15];
            default:inA16_1 <= 'd0;
        endcase
    end
    else begin
        inA16_1 <= 'd0;
    end
end

//PE PE1(.clk(clk),.rst_n(rst_n),.inA(),.inB(),.inW(),.outC(),.outD());

PE PE1_1 (.clk(clk),.rst_n(rst_n),.inA( inA11),.inB('d0),.inW(w_matrix[0][0]),.outC(outC11),.outD(outD11));
PE PE1_2 (.clk(clk),.rst_n(rst_n),.inA(outD11),.inB('d0),.inW(w_matrix[0][1]),.outC(outC12),.outD(outD12));
PE PE1_3 (.clk(clk),.rst_n(rst_n),.inA(outD12),.inB('d0),.inW(w_matrix[0][2]),.outC(outC13),.outD(outD13));
PE PE1_4 (.clk(clk),.rst_n(rst_n),.inA(outD13),.inB('d0),.inW(w_matrix[0][3]),.outC(outC14),.outD(outD14));
PE PE1_5 (.clk(clk),.rst_n(rst_n),.inA(outD14),.inB('d0),.inW(w_matrix[0][4]),.outC(outC15),.outD(outD15));
PE PE1_6 (.clk(clk),.rst_n(rst_n),.inA(outD15),.inB('d0),.inW(w_matrix[0][5]),.outC(outC16),.outD(outD16));
PE PE1_7 (.clk(clk),.rst_n(rst_n),.inA(outD16),.inB('d0),.inW(w_matrix  [0][6]),.outC(outC17),.outD(outD17));
PE PE1_8 (.clk(clk),.rst_n(rst_n),.inA(outD17),.inB('d0),.inW(  w_matrix[0][7]),.outC(outC18),.outD(outD18));
PE PE1_9 (.clk(clk),.rst_n(rst_n),.inA(outD18),.inB('d0),.inW(  w_matrix[0][8]),.outC(  outC19 ),.outD( outD19 ));
PE PE1_10(.clk(clk),.rst_n(rst_n),.inA(outD19),.inB('d0),.inW(  w_matrix[0][9]),.outC( outC1_10),.outD(outD1_10));
PE PE1_11(.clk(clk),.rst_n(rst_n),.inA(outD1_10),.inB('d0),.inW(w_matrix[0][10]),.outC(outC1_11),.outD(outD1_11));
PE PE1_12(.clk(clk),.rst_n(rst_n),.inA(outD1_11),.inB('d0),.inW(w_matrix[0][11]),.outC(outC1_12),.outD(outD1_12));
PE PE1_13(.clk(clk),.rst_n(rst_n),.inA(outD1_12),.inB('d0),.inW(w_matrix[0][12]),.outC(outC1_13),.outD(outD1_13));
PE PE1_14(.clk(clk),.rst_n(rst_n),.inA(outD1_13),.inB('d0),.inW(w_matrix[0][13]),.outC(outC1_14),.outD(outD1_14));
PE PE1_15(.clk(clk),.rst_n(rst_n),.inA(outD1_14),.inB('d0),.inW(w_matrix[0][14]),.outC(outC1_15),.outD(outD1_15));
PE PE1_16(.clk(clk),.rst_n(rst_n),.inA(outD1_15),.inB('d0),.inW(w_matrix[0][15]),.outC(outC1_16),.outD(outD1_16));
                                                                            

PE PE2_1 (.clk(clk),.rst_n(rst_n),.inA( inA21),.inB(outC11),.inW(w_matrix[1][0]),.outC(outC21),.outD(outD21));
PE PE2_2 (.clk(clk),.rst_n(rst_n),.inA(outD21),.inB(outC12),.inW(w_matrix[1][1]),.outC(outC22),.outD(outD22));
PE PE2_3 (.clk(clk),.rst_n(rst_n),.inA(outD22),.inB(outC13),.inW(w_matrix[1][2]),.outC(outC23),.outD(outD23));
PE PE2_4 (.clk(clk),.rst_n(rst_n),.inA(outD23),.inB(outC14),.inW(w_matrix[1][3]),.outC(outC24),.outD(outD24));
PE PE2_5 (.clk(clk),.rst_n(rst_n),.inA(outD24),.inB(outC15),.inW(w_matrix[1][4]),.outC(outC25),.outD(outD25));
PE PE2_6 (.clk(clk),.rst_n(rst_n),.inA(outD25),.inB(outC16),.inW(w_matrix[1][5]),.outC(outC26),.outD(outD26));
PE PE2_7 (.clk(clk),.rst_n(rst_n),.inA(outD26),.inB(outC17),.inW(w_matrix[1][6]),.outC(outC27),.outD(outD27));
PE PE2_8 (.clk(clk),.rst_n(rst_n),.inA(outD27),.inB(outC18),.inW(w_matrix[1][7]),.outC(outC28),.outD(outD28));
PE PE2_9 (.clk(clk),.rst_n(rst_n),.inA(outD28),.inB(outC19),.inW(  w_matrix[1][8]),.outC(  outC29 ),.outD(  outD29 ));
PE PE2_10(.clk(clk),.rst_n(rst_n),.inA(outD29),.inB(outC1_10),.inW(  w_matrix[1][9]),.outC( outC2_10),.outD(outD2_10));
PE PE2_11(.clk(clk),.rst_n(rst_n),.inA(outD2_10),.inB(outC1_11),.inW(w_matrix[1][10]),.outC(outC2_11),.outD(outD2_11));
PE PE2_12(.clk(clk),.rst_n(rst_n),.inA(outD2_11),.inB(outC1_12),.inW(w_matrix[1][11]),.outC(outC2_12),.outD(outD2_12));
PE PE2_13(.clk(clk),.rst_n(rst_n),.inA(outD2_12),.inB(outC1_13),.inW(w_matrix[1][12]),.outC(outC2_13),.outD(outD2_13));
PE PE2_14(.clk(clk),.rst_n(rst_n),.inA(outD2_13),.inB(outC1_14),.inW(w_matrix[1][13]),.outC(outC2_14),.outD(outD2_14));
PE PE2_15(.clk(clk),.rst_n(rst_n),.inA(outD2_14),.inB(outC1_15),.inW(w_matrix[1][14]),.outC(outC2_15),.outD(outD2_15));
PE PE2_16(.clk(clk),.rst_n(rst_n),.inA(outD2_15),.inB(outC1_16),.inW(w_matrix[1][15]),.outC(outC2_16),.outD(outD2_16));

PE PE3_1(.clk(clk),.rst_n(rst_n),.inA(inA31),.inB(outC21),.inW(w_matrix[2][0]),.outC(outC31),.outD(outD31));
PE PE3_2(.clk(clk),.rst_n(rst_n),.inA(outD31),.inB(outC22),.inW(w_matrix[2][1]),.outC(outC32),.outD(outD32));
PE PE3_3(.clk(clk),.rst_n(rst_n),.inA(outD32),.inB(outC23),.inW(w_matrix[2][2]),.outC(outC33),.outD(outD33));
PE PE3_4(.clk(clk),.rst_n(rst_n),.inA(outD33),.inB(outC24),.inW(w_matrix[2][3]),.outC(outC34),.outD(outD34));
PE PE3_5(.clk(clk),.rst_n(rst_n),.inA(outD34),.inB(outC25),.inW(w_matrix[2][4]),.outC(outC35),.outD(outD35));
PE PE3_6(.clk(clk),.rst_n(rst_n),.inA(outD35),.inB(outC26),.inW(w_matrix[2][5]),.outC(outC36),.outD(outD36));
PE PE3_7(.clk(clk),.rst_n(rst_n),.inA(outD36),.inB(outC27),.inW(w_matrix[2][6]),.outC(outC37),.outD(outD37));
PE PE3_8(.clk(clk),.rst_n(rst_n),.inA(outD37),.inB(outC28),.inW(w_matrix[2][7]),.outC(outC38),.outD(outD38));
PE PE3_9 (.clk(clk),.rst_n(rst_n),.inA(outD38),.inB(  outC29),.inW(  w_matrix[2][8]),.outC( outC39 ),.outD( outD39 ));
PE PE3_10(.clk(clk),.rst_n(rst_n),.inA(outD39),.inB(  outC2_10),.inW(w_matrix[2][9]),.outC( outC3_10),.outD(outD3_10));
PE PE3_11(.clk(clk),.rst_n(rst_n),.inA(outD3_10),.inB(outC2_11),.inW(w_matrix[2][10]),.outC(outC3_11),.outD(outD3_11));
PE PE3_12(.clk(clk),.rst_n(rst_n),.inA(outD3_11),.inB(outC2_12),.inW(w_matrix[2][11]),.outC(outC3_12),.outD(outD3_12));
PE PE3_13(.clk(clk),.rst_n(rst_n),.inA(outD3_12),.inB(outC2_13),.inW(w_matrix[2][12]),.outC(outC3_13),.outD(outD3_13));
PE PE3_14(.clk(clk),.rst_n(rst_n),.inA(outD3_13),.inB(outC2_14),.inW(w_matrix[2][13]),.outC(outC3_14),.outD(outD3_14));
PE PE3_15(.clk(clk),.rst_n(rst_n),.inA(outD3_14),.inB(outC2_15),.inW(w_matrix[2][14]),.outC(outC3_15),.outD(outD3_15));
PE PE3_16(.clk(clk),.rst_n(rst_n),.inA(outD3_15),.inB(outC2_16),.inW(w_matrix[2][15]),.outC(outC3_16),.outD(outD3_16));

PE PE4_1(.clk(clk),.rst_n(rst_n),.inA(inA41),.inB(outC31),.inW(w_matrix[3][0]),.outC(outC41),.outD(outD41));
PE PE4_2(.clk(clk),.rst_n(rst_n),.inA(outD41),.inB(outC32),.inW(w_matrix[3][1]),.outC(outC42),.outD(outD42));
PE PE4_3(.clk(clk),.rst_n(rst_n),.inA(outD42),.inB(outC33),.inW(w_matrix[3][2]),.outC(outC43),.outD(outD43));
PE PE4_4(.clk(clk),.rst_n(rst_n),.inA(outD43),.inB(outC34),.inW(w_matrix[3][3]),.outC(outC44),.outD(outD44));
PE PE4_5(.clk(clk),.rst_n(rst_n),.inA(outD44),.inB(outC35),.inW(w_matrix[3][4]),.outC(outC45),.outD(outD45));
PE PE4_6(.clk(clk),.rst_n(rst_n),.inA(outD45),.inB(outC36),.inW(w_matrix[3][5]),.outC(outC46),.outD(outD46));
PE PE4_7(.clk(clk),.rst_n(rst_n),.inA(outD46),.inB(outC37),.inW(w_matrix[3][6]),.outC(outC47),.outD(outD47));
PE PE4_8(.clk(clk),.rst_n(rst_n),.inA(outD47),.inB(outC38),.inW(w_matrix[3][7]),.outC(outC48),.outD(outD48));
PE PE4_9 (.clk(clk),.rst_n(rst_n),.inA(outD48),.inB(  outC39),.inW(  w_matrix[3][8]),.outC( outC49 ),.outD( outD49 ));
PE PE4_10(.clk(clk),.rst_n(rst_n),.inA(outD49),.inB(  outC3_10),.inW(w_matrix[3][9]),.outC( outC4_10),.outD(outD4_10));
PE PE4_11(.clk(clk),.rst_n(rst_n),.inA(outD4_10),.inB(outC3_11),.inW(w_matrix[3][10]),.outC(outC4_11),.outD(outD4_11));
PE PE4_12(.clk(clk),.rst_n(rst_n),.inA(outD4_11),.inB(outC3_12),.inW(w_matrix[3][11]),.outC(outC4_12),.outD(outD4_12));
PE PE4_13(.clk(clk),.rst_n(rst_n),.inA(outD4_12),.inB(outC3_13),.inW(w_matrix[3][12]),.outC(outC4_13),.outD(outD4_13));
PE PE4_14(.clk(clk),.rst_n(rst_n),.inA(outD4_13),.inB(outC3_14),.inW(w_matrix[3][13]),.outC(outC4_14),.outD(outD4_14));
PE PE4_15(.clk(clk),.rst_n(rst_n),.inA(outD4_14),.inB(outC3_15),.inW(w_matrix[3][14]),.outC(outC4_15),.outD(outD4_15));
PE PE4_16(.clk(clk),.rst_n(rst_n),.inA(outD4_15),.inB(outC3_16),.inW(w_matrix[3][15]),.outC(outC4_16),.outD(outD4_16));


PE PE5_1(.clk(clk),.rst_n(rst_n),.inA (inA51),.inB(outC41),.inW(w_matrix[4][0]),.outC(outC51),.outD(outD51));
PE PE5_2(.clk(clk),.rst_n(rst_n),.inA(outD51),.inB(outC42),.inW(w_matrix[4][1]),.outC(outC52),.outD(outD52));
PE PE5_3(.clk(clk),.rst_n(rst_n),.inA(outD52),.inB(outC43),.inW(w_matrix[4][2]),.outC(outC53),.outD(outD53));
PE PE5_4(.clk(clk),.rst_n(rst_n),.inA(outD53),.inB(outC44),.inW(w_matrix[4][3]),.outC(outC54),.outD(outD54));
PE PE5_5(.clk(clk),.rst_n(rst_n),.inA(outD54),.inB(outC45),.inW(w_matrix[4][4]),.outC(outC55),.outD(outD55));
PE PE5_6(.clk(clk),.rst_n(rst_n),.inA(outD55),.inB(outC46),.inW(w_matrix[4][5]),.outC(outC56),.outD(outD56));
PE PE5_7(.clk(clk),.rst_n(rst_n),.inA(outD56),.inB(outC47),.inW(w_matrix[4][6]),.outC(outC57),.outD(outD57));
PE PE5_8(.clk(clk),.rst_n(rst_n),.inA(outD57),.inB(outC48),.inW(w_matrix[4][7]),.outC(outC58),.outD(outD58));
PE PE5_9 (.clk(clk),.rst_n(rst_n),.inA(outD58),.inB(  outC49),.inW(  w_matrix[4][8]),.outC( outC59 ),.outD( outD59 ));
PE PE5_10(.clk(clk),.rst_n(rst_n),.inA(outD59),.inB(  outC4_10),.inW(w_matrix[4][9]),.outC( outC5_10),.outD(outD5_10));
PE PE5_11(.clk(clk),.rst_n(rst_n),.inA(outD5_10),.inB(outC4_11),.inW(w_matrix[4][10]),.outC(outC5_11),.outD(outD5_11));
PE PE5_12(.clk(clk),.rst_n(rst_n),.inA(outD5_11),.inB(outC4_12),.inW(w_matrix[4][11]),.outC(outC5_12),.outD(outD5_12));
PE PE5_13(.clk(clk),.rst_n(rst_n),.inA(outD5_12),.inB(outC4_13),.inW(w_matrix[4][12]),.outC(outC5_13),.outD(outD5_13));
PE PE5_14(.clk(clk),.rst_n(rst_n),.inA(outD5_13),.inB(outC4_14),.inW(w_matrix[4][13]),.outC(outC5_14),.outD(outD5_14));
PE PE5_15(.clk(clk),.rst_n(rst_n),.inA(outD5_14),.inB(outC4_15),.inW(w_matrix[4][14]),.outC(outC5_15),.outD(outD5_15));
PE PE5_16(.clk(clk),.rst_n(rst_n),.inA(outD5_15),.inB(outC4_16),.inW(w_matrix[4][15]),.outC(outC5_16),.outD(outD5_16));


PE PE6_1(.clk(clk),.rst_n(rst_n),.inA (inA61),.inB(outC51),.inW(w_matrix[5][0]),.outC(outC61),.outD(outD61));
PE PE6_2(.clk(clk),.rst_n(rst_n),.inA(outD61),.inB(outC52),.inW(w_matrix[5][1]),.outC(outC62),.outD(outD62));
PE PE6_3(.clk(clk),.rst_n(rst_n),.inA(outD62),.inB(outC53),.inW(w_matrix[5][2]),.outC(outC63),.outD(outD63));
PE PE6_4(.clk(clk),.rst_n(rst_n),.inA(outD63),.inB(outC54),.inW(w_matrix[5][3]),.outC(outC64),.outD(outD64));
PE PE6_5(.clk(clk),.rst_n(rst_n),.inA(outD64),.inB(outC55),.inW(w_matrix[5][4]),.outC(outC65),.outD(outD65));
PE PE6_6(.clk(clk),.rst_n(rst_n),.inA(outD65),.inB(outC56),.inW(w_matrix[5][5]),.outC(outC66),.outD(outD66));
PE PE6_7(.clk(clk),.rst_n(rst_n),.inA(outD66),.inB(outC57),.inW(w_matrix[5][6]),.outC(outC67),.outD(outD67));
PE PE6_8(.clk(clk),.rst_n(rst_n),.inA(outD67),.inB(outC58),.inW(w_matrix[5][7]),.outC(outC68),.outD(outD68));
PE PE6_9 (.clk(clk),.rst_n(rst_n),.inA(outD68),.inB(  outC59),.inW(  w_matrix[5][8]),.outC( outC69 ),.outD( outD69 ));
PE PE6_10(.clk(clk),.rst_n(rst_n),.inA(outD69),.inB(  outC5_10),.inW(w_matrix[5][9]),.outC( outC6_10),.outD(outD6_10));
PE PE6_11(.clk(clk),.rst_n(rst_n),.inA(outD6_10),.inB(outC5_11),.inW(w_matrix[5][10]),.outC(outC6_11),.outD(outD6_11));
PE PE6_12(.clk(clk),.rst_n(rst_n),.inA(outD6_11),.inB(outC5_12),.inW(w_matrix[5][11]),.outC(outC6_12),.outD(outD6_12));
PE PE6_13(.clk(clk),.rst_n(rst_n),.inA(outD6_12),.inB(outC5_13),.inW(w_matrix[5][12]),.outC(outC6_13),.outD(outD6_13));
PE PE6_14(.clk(clk),.rst_n(rst_n),.inA(outD6_13),.inB(outC5_14),.inW(w_matrix[5][13]),.outC(outC6_14),.outD(outD6_14));
PE PE6_15(.clk(clk),.rst_n(rst_n),.inA(outD6_14),.inB(outC5_15),.inW(w_matrix[5][14]),.outC(outC6_15),.outD(outD6_15));
PE PE6_16(.clk(clk),.rst_n(rst_n),.inA(outD6_15),.inB(outC5_16),.inW(w_matrix[5][15]),.outC(outC6_16),.outD(outD6_16));

PE PE7_1(.clk(clk),.rst_n(rst_n),.inA (inA71),.inB(outC61),.inW(w_matrix[6][0]),.outC(outC71),.outD(outD71));
PE PE7_2(.clk(clk),.rst_n(rst_n),.inA(outD71),.inB(outC62),.inW(w_matrix[6][1]),.outC(outC72),.outD(outD72));
PE PE7_3(.clk(clk),.rst_n(rst_n),.inA(outD72),.inB(outC63),.inW(w_matrix[6][2]),.outC(outC73),.outD(outD73));
PE PE7_4(.clk(clk),.rst_n(rst_n),.inA(outD73),.inB(outC64),.inW(w_matrix[6][3]),.outC(outC74),.outD(outD74));
PE PE7_5(.clk(clk),.rst_n(rst_n),.inA(outD74),.inB(outC65),.inW(w_matrix[6][4]),.outC(outC75),.outD(outD75));
PE PE7_6(.clk(clk),.rst_n(rst_n),.inA(outD75),.inB(outC66),.inW(w_matrix[6][5]),.outC(outC76),.outD(outD76));
PE PE7_7(.clk(clk),.rst_n(rst_n),.inA(outD76),.inB(outC67),.inW(w_matrix[6][6]),.outC(outC77),.outD(outD77));
PE PE7_8(.clk(clk),.rst_n(rst_n),.inA(outD77),.inB(outC68),.inW(w_matrix[6][7]),.outC(outC78),.outD(outD78));
PE PE7_9 (.clk(clk),.rst_n(rst_n),.inA(outD78),.inB(  outC69),.inW(  w_matrix[6][8]),.outC( outC79 ),.outD( outD79 ));
PE PE7_10(.clk(clk),.rst_n(rst_n),.inA(outD79),.inB(  outC6_10),.inW(w_matrix[6][9]),.outC( outC7_10),.outD(outD7_10));
PE PE7_11(.clk(clk),.rst_n(rst_n),.inA(outD7_10),.inB(outC6_11),.inW(w_matrix[6][10]),.outC(outC7_11),.outD(outD7_11));
PE PE7_12(.clk(clk),.rst_n(rst_n),.inA(outD7_11),.inB(outC6_12),.inW(w_matrix[6][11]),.outC(outC7_12),.outD(outD7_12));
PE PE7_13(.clk(clk),.rst_n(rst_n),.inA(outD7_12),.inB(outC6_13),.inW(w_matrix[6][12]),.outC(outC7_13),.outD(outD7_13));
PE PE7_14(.clk(clk),.rst_n(rst_n),.inA(outD7_13),.inB(outC6_14),.inW(w_matrix[6][13]),.outC(outC7_14),.outD(outD7_14));
PE PE7_15(.clk(clk),.rst_n(rst_n),.inA(outD7_14),.inB(outC6_15),.inW(w_matrix[6][14]),.outC(outC7_15),.outD(outD7_15));
PE PE7_16(.clk(clk),.rst_n(rst_n),.inA(outD7_15),.inB(outC6_16),.inW(w_matrix[6][15]),.outC(outC7_16),.outD(outD7_16));

PE PE8_1(.clk(clk),.rst_n(rst_n),.inA (inA81),.inB(outC71),.inW(w_matrix[7][0]),.outC(outC81),.outD(outD81));
PE PE8_2(.clk(clk),.rst_n(rst_n),.inA(outD81),.inB(outC72),.inW(w_matrix[7][1]),.outC(outC82),.outD(outD82));
PE PE8_3(.clk(clk),.rst_n(rst_n),.inA(outD82),.inB(outC73),.inW(w_matrix[7][2]),.outC(outC83),.outD(outD83));
PE PE8_4(.clk(clk),.rst_n(rst_n),.inA(outD83),.inB(outC74),.inW(w_matrix[7][3]),.outC(outC84),.outD(outD84));
PE PE8_5(.clk(clk),.rst_n(rst_n),.inA(outD84),.inB(outC75),.inW(w_matrix[7][4]),.outC(outC85),.outD(outD85));
PE PE8_6(.clk(clk),.rst_n(rst_n),.inA(outD85),.inB(outC76),.inW(w_matrix[7][5]),.outC(outC86),.outD(outD86));
PE PE8_7(.clk(clk),.rst_n(rst_n),.inA(outD86),.inB(outC77),.inW(w_matrix[7][6]),.outC(outC87),.outD(outD87));
PE PE8_8(.clk(clk),.rst_n(rst_n),.inA(outD87),.inB(outC78),.inW(w_matrix[7][7]),.outC(outC88),.outD(outD88));
PE PE8_9 (.clk(clk),.rst_n(rst_n),.inA(outD88),.inB(  outC79),.inW(  w_matrix[7][8]),.outC( outC89 ),.outD( outD89 ));
PE PE8_10(.clk(clk),.rst_n(rst_n),.inA(outD89),.inB(  outC7_10),.inW(w_matrix[7][9]),.outC( outC8_10),.outD(outD8_10));
PE PE8_11(.clk(clk),.rst_n(rst_n),.inA(outD8_10),.inB(outC7_11),.inW(w_matrix[7][10]),.outC(outC8_11),.outD(outD8_11));
PE PE8_12(.clk(clk),.rst_n(rst_n),.inA(outD8_11),.inB(outC7_12),.inW(w_matrix[7][11]),.outC(outC8_12),.outD(outD8_12));
PE PE8_13(.clk(clk),.rst_n(rst_n),.inA(outD8_12),.inB(outC7_13),.inW(w_matrix[7][12]),.outC(outC8_13),.outD(outD8_13));
PE PE8_14(.clk(clk),.rst_n(rst_n),.inA(outD8_13),.inB(outC7_14),.inW(w_matrix[7][13]),.outC(outC8_14),.outD(outD8_14));
PE PE8_15(.clk(clk),.rst_n(rst_n),.inA(outD8_14),.inB(outC7_15),.inW(w_matrix[7][14]),.outC(outC8_15),.outD(outD8_15));
PE PE8_16(.clk(clk),.rst_n(rst_n),.inA(outD8_15),.inB(outC7_16),.inW(w_matrix[7][15]),.outC(outC8_16),.outD(outD8_16));

PE PE9_1(.clk(clk),.rst_n(rst_n),.inA ( inA91),.inB(  outC81),.inW(  w_matrix[8][0]),.outC( outC91),.outD(  outD91));
PE PE9_2(.clk(clk),.rst_n(rst_n),.inA( outD91),.inB(  outC82),.inW(  w_matrix[8][1]),.outC( outC92),.outD(  outD92));
PE PE9_3(.clk(clk),.rst_n(rst_n),.inA( outD92),.inB(  outC83),.inW(  w_matrix[8][2]),.outC( outC93),.outD(  outD93));
PE PE9_4(.clk(clk),.rst_n(rst_n),.inA( outD93),.inB(  outC84),.inW(  w_matrix[8][3]),.outC( outC94),.outD(  outD94));
PE PE9_5(.clk(clk),.rst_n(rst_n),.inA( outD94),.inB(  outC85),.inW(  w_matrix[8][4]),.outC( outC95),.outD(  outD95));
PE PE9_6(.clk(clk),.rst_n(rst_n),.inA( outD95),.inB(  outC86),.inW(  w_matrix[8][5]),.outC( outC96),.outD(  outD96));
PE PE9_7(.clk(clk),.rst_n(rst_n),.inA( outD96),.inB(  outC87),.inW(  w_matrix[8][6]),.outC( outC97),.outD(  outD97));
PE PE9_8(.clk(clk),.rst_n(rst_n),.inA( outD97),.inB(  outC88),.inW(  w_matrix[8][7]),.outC( outC98),.outD(  outD98));
PE PE9_9 (.clk(clk),.rst_n(rst_n),.inA(outD98),.inB(  outC89),.inW(  w_matrix[8][8]),.outC( outC99 ),.outD( outD99 ));
PE PE9_10(.clk(clk),.rst_n(rst_n),.inA(outD99),.inB(  outC8_10),.inW(w_matrix[8][9]),.outC( outC9_10),.outD(outD9_10));
PE PE9_11(.clk(clk),.rst_n(rst_n),.inA(outD9_10),.inB(outC8_11),.inW(w_matrix[8][10]),.outC(outC9_11),.outD(outD9_11));
PE PE9_12(.clk(clk),.rst_n(rst_n),.inA(outD9_11),.inB(outC8_12),.inW(w_matrix[8][11]),.outC(outC9_12),.outD(outD9_12));
PE PE9_13(.clk(clk),.rst_n(rst_n),.inA(outD9_12),.inB(outC8_13),.inW(w_matrix[8][12]),.outC(outC9_13),.outD(outD9_13));
PE PE9_14(.clk(clk),.rst_n(rst_n),.inA(outD9_13),.inB(outC8_14),.inW(w_matrix[8][13]),.outC(outC9_14),.outD(outD9_14));
PE PE9_15(.clk(clk),.rst_n(rst_n),.inA(outD9_14),.inB(outC8_15),.inW(w_matrix[8][14]),.outC(outC9_15),.outD(outD9_15));
PE PE9_16(.clk(clk),.rst_n(rst_n),.inA(outD9_15),.inB(outC8_16),.inW(w_matrix[8][15]),.outC(outC9_16),.outD(outD9_16));

PE PE10_1(.clk(clk),.rst_n(rst_n),.inA ( inA10_1),.inB( outC91),.inW(  w_matrix[9][0]),.outC( outC10_1),.outD( outD10_1));
PE PE10_2(.clk(clk),.rst_n(rst_n),.inA( outD10_1),.inB( outC92),.inW(  w_matrix[9][1]),.outC( outC10_2),.outD( outD10_2));
PE PE10_3(.clk(clk),.rst_n(rst_n),.inA( outD10_2),.inB( outC93),.inW(  w_matrix[9][2]),.outC( outC10_3),.outD( outD10_3));
PE PE10_4(.clk(clk),.rst_n(rst_n),.inA( outD10_3),.inB( outC94),.inW(  w_matrix[9][3]),.outC( outC10_4),.outD( outD10_4));
PE PE10_5(.clk(clk),.rst_n(rst_n),.inA( outD10_4),.inB( outC95),.inW(  w_matrix[9][4]),.outC( outC10_5),.outD( outD10_5));
PE PE10_6(.clk(clk),.rst_n(rst_n),.inA( outD10_5),.inB( outC96),.inW(  w_matrix[9][5]),.outC( outC10_6),.outD( outD10_6));
PE PE10_7(.clk(clk),.rst_n(rst_n),.inA( outD10_6),.inB( outC97),.inW(  w_matrix[9][6]),.outC( outC10_7),.outD( outD10_7));
PE PE10_8(.clk(clk),.rst_n(rst_n),.inA( outD10_7),.inB( outC98),.inW(  w_matrix[9][7]),.outC( outC10_8),.outD( outD10_8));
PE PE10_9 (.clk(clk),.rst_n(rst_n),.inA(outD10_8),.inB( outC99),.inW(  w_matrix[9][8]),.outC( outC10_9 ),.outD(outD10_9 ));
PE PE10_10(.clk(clk),.rst_n(rst_n),.inA(outD10_9),.inB( outC9_10),.inW(w_matrix[9][9]),.outC( outC10_10),.outD(outD10_10));
PE PE10_11(.clk(clk),.rst_n(rst_n),.inA(outD10_10),.inB(outC9_11),.inW(w_matrix[9][10]),.outC(outC10_11),.outD(outD10_11));
PE PE10_12(.clk(clk),.rst_n(rst_n),.inA(outD10_11),.inB(outC9_12),.inW(w_matrix[9][11]),.outC(outC10_12),.outD(outD10_12));
PE PE10_13(.clk(clk),.rst_n(rst_n),.inA(outD10_12),.inB(outC9_13),.inW(w_matrix[9][12]),.outC(outC10_13),.outD(outD10_13));
PE PE10_14(.clk(clk),.rst_n(rst_n),.inA(outD10_13),.inB(outC9_14),.inW(w_matrix[9][13]),.outC(outC10_14),.outD(outD10_14));
PE PE10_15(.clk(clk),.rst_n(rst_n),.inA(outD10_14),.inB(outC9_15),.inW(w_matrix[9][14]),.outC(outC10_15),.outD(outD10_15));
PE PE10_16(.clk(clk),.rst_n(rst_n),.inA(outD10_15),.inB(outC9_16),.inW(w_matrix[9][15]),.outC(outC10_16),.outD(outD10_16));

PE PE11_1(.clk(clk),.rst_n(rst_n),.inA ( inA11_1),.inB( outC10_1),.inW( w_matrix[10][0]),.outC( outC11_1),.outD( outD11_1));
PE PE11_2(.clk(clk),.rst_n(rst_n),.inA( outD11_1),.inB( outC10_2),.inW( w_matrix[10][1]),.outC( outC11_2),.outD( outD11_2));
PE PE11_3(.clk(clk),.rst_n(rst_n),.inA( outD11_2),.inB( outC10_3),.inW( w_matrix[10][2]),.outC( outC11_3),.outD( outD11_3));
PE PE11_4(.clk(clk),.rst_n(rst_n),.inA( outD11_3),.inB( outC10_4),.inW( w_matrix[10][3]),.outC( outC11_4),.outD( outD11_4));
PE PE11_5(.clk(clk),.rst_n(rst_n),.inA( outD11_4),.inB( outC10_5),.inW( w_matrix[10][4]),.outC( outC11_5),.outD( outD11_5));
PE PE11_6(.clk(clk),.rst_n(rst_n),.inA( outD11_5),.inB( outC10_6),.inW( w_matrix[10][5]),.outC( outC11_6),.outD( outD11_6));
PE PE11_7(.clk(clk),.rst_n(rst_n),.inA( outD11_6),.inB( outC10_7),.inW( w_matrix[10][6]),.outC( outC11_7),.outD( outD11_7));
PE PE11_8(.clk(clk),.rst_n(rst_n),.inA( outD11_7),.inB( outC10_8),.inW( w_matrix[10][7]),.outC( outC11_8),.outD( outD11_8));
PE PE11_9 (.clk(clk),.rst_n(rst_n),.inA(outD11_8),.inB( outC10_9),.inW( w_matrix[10][8]),.outC( outC11_9 ),.outD(outD11_9 ));
PE PE11_10(.clk(clk),.rst_n(rst_n),.inA(outD11_9),.inB( outC10_10),.inW(w_matrix[10][9]),.outC( outC11_10),.outD(outD11_10));
PE PE11_11(.clk(clk),.rst_n(rst_n),.inA(outD11_10),.inB(outC10_11),.inW(w_matrix[10][10]),.outC(outC11_11),.outD(outD11_11));
PE PE11_12(.clk(clk),.rst_n(rst_n),.inA(outD11_11),.inB(outC10_12),.inW(w_matrix[10][11]),.outC(outC11_12),.outD(outD11_12));
PE PE11_13(.clk(clk),.rst_n(rst_n),.inA(outD11_12),.inB(outC10_13),.inW(w_matrix[10][12]),.outC(outC11_13),.outD(outD11_13));
PE PE11_14(.clk(clk),.rst_n(rst_n),.inA(outD11_13),.inB(outC10_14),.inW(w_matrix[10][13]),.outC(outC11_14),.outD(outD11_14));
PE PE11_15(.clk(clk),.rst_n(rst_n),.inA(outD11_14),.inB(outC10_15),.inW(w_matrix[10][14]),.outC(outC11_15),.outD(outD11_15));
PE PE11_16(.clk(clk),.rst_n(rst_n),.inA(outD11_15),.inB(outC10_16),.inW(w_matrix[10][15]),.outC(outC11_16),.outD(outD11_16));

PE PE12_1(.clk(clk),.rst_n(rst_n),.inA ( inA12_1),.inB( outC11_1),.inW( w_matrix[11][0]),.outC( outC12_1),.outD( outD12_1));
PE PE12_2(.clk(clk),.rst_n(rst_n),.inA( outD12_1),.inB( outC11_2),.inW( w_matrix[11][1]),.outC( outC12_2),.outD( outD12_2));
PE PE12_3(.clk(clk),.rst_n(rst_n),.inA( outD12_2),.inB( outC11_3),.inW( w_matrix[11][2]),.outC( outC12_3),.outD( outD12_3));
PE PE12_4(.clk(clk),.rst_n(rst_n),.inA( outD12_3),.inB( outC11_4),.inW( w_matrix[11][3]),.outC( outC12_4),.outD( outD12_4));
PE PE12_5(.clk(clk),.rst_n(rst_n),.inA( outD12_4),.inB( outC11_5),.inW( w_matrix[11][4]),.outC( outC12_5),.outD( outD12_5));
PE PE12_6(.clk(clk),.rst_n(rst_n),.inA( outD12_5),.inB( outC11_6),.inW( w_matrix[11][5]),.outC( outC12_6),.outD( outD12_6));
PE PE12_7(.clk(clk),.rst_n(rst_n),.inA( outD12_6),.inB( outC11_7),.inW( w_matrix[11][6]),.outC( outC12_7),.outD( outD12_7));
PE PE12_8(.clk(clk),.rst_n(rst_n),.inA( outD12_7),.inB( outC11_8),.inW( w_matrix[11][7]),.outC( outC12_8),.outD( outD12_8));
PE PE12_9 (.clk(clk),.rst_n(rst_n),.inA(outD12_8),.inB( outC11_9),.inW( w_matrix[11][8]),.outC( outC12_9 ),.outD(outD12_9 ));
PE PE12_10(.clk(clk),.rst_n(rst_n),.inA(outD12_9),.inB( outC11_10),.inW(w_matrix[11][9]),.outC( outC12_10),.outD(outD12_10));
PE PE12_11(.clk(clk),.rst_n(rst_n),.inA(outD12_10),.inB(outC11_11),.inW(w_matrix[11][10]),.outC(outC12_11),.outD(outD12_11));
PE PE12_12(.clk(clk),.rst_n(rst_n),.inA(outD12_11),.inB(outC11_12),.inW(w_matrix[11][11]),.outC(outC12_12),.outD(outD12_12));
PE PE12_13(.clk(clk),.rst_n(rst_n),.inA(outD12_12),.inB(outC11_13),.inW(w_matrix[11][12]),.outC(outC12_13),.outD(outD12_13));
PE PE12_14(.clk(clk),.rst_n(rst_n),.inA(outD12_13),.inB(outC11_14),.inW(w_matrix[11][13]),.outC(outC12_14),.outD(outD12_14));
PE PE12_15(.clk(clk),.rst_n(rst_n),.inA(outD12_14),.inB(outC11_15),.inW(w_matrix[11][14]),.outC(outC12_15),.outD(outD12_15));
PE PE12_16(.clk(clk),.rst_n(rst_n),.inA(outD12_15),.inB(outC11_16),.inW(w_matrix[11][15]),.outC(outC12_16),.outD(outD12_16));

PE PE13_1(.clk(clk),.rst_n(rst_n),.inA ( inA13_1),.inB( outC12_1),.inW( w_matrix[12][0]),.outC( outC13_1),.outD( outD13_1));
PE PE13_2(.clk(clk),.rst_n(rst_n),.inA( outD13_1),.inB( outC12_2),.inW( w_matrix[12][1]),.outC( outC13_2),.outD( outD13_2));
PE PE13_3(.clk(clk),.rst_n(rst_n),.inA( outD13_2),.inB( outC12_3),.inW( w_matrix[12][2]),.outC( outC13_3),.outD( outD13_3));
PE PE13_4(.clk(clk),.rst_n(rst_n),.inA( outD13_3),.inB( outC12_4),.inW( w_matrix[12][3]),.outC( outC13_4),.outD( outD13_4));
PE PE13_5(.clk(clk),.rst_n(rst_n),.inA( outD13_4),.inB( outC12_5),.inW( w_matrix[12][4]),.outC( outC13_5),.outD( outD13_5));
PE PE13_6(.clk(clk),.rst_n(rst_n),.inA( outD13_5),.inB( outC12_6),.inW( w_matrix[12][5]),.outC( outC13_6),.outD( outD13_6));
PE PE13_7(.clk(clk),.rst_n(rst_n),.inA( outD13_6),.inB( outC12_7),.inW( w_matrix[12][6]),.outC( outC13_7),.outD( outD13_7));
PE PE13_8(.clk(clk),.rst_n(rst_n),.inA( outD13_7),.inB( outC12_8),.inW( w_matrix[12][7]),.outC( outC13_8),.outD( outD13_8));
PE PE13_9 (.clk(clk),.rst_n(rst_n),.inA(outD13_8),.inB( outC12_9),.inW( w_matrix[12][8]),.outC( outC13_9 ),.outD(outD13_9 ));
PE PE13_10(.clk(clk),.rst_n(rst_n),.inA(outD13_9),.inB( outC12_10),.inW(w_matrix[12][9]),.outC( outC13_10),.outD(outD13_10));
PE PE13_11(.clk(clk),.rst_n(rst_n),.inA(outD13_10),.inB(outC12_11),.inW(w_matrix[12][10]),.outC(outC13_11),.outD(outD13_11));
PE PE13_12(.clk(clk),.rst_n(rst_n),.inA(outD13_11),.inB(outC12_12),.inW(w_matrix[12][11]),.outC(outC13_12),.outD(outD13_12));
PE PE13_13(.clk(clk),.rst_n(rst_n),.inA(outD13_12),.inB(outC12_13),.inW(w_matrix[12][12]),.outC(outC13_13),.outD(outD13_13));
PE PE13_14(.clk(clk),.rst_n(rst_n),.inA(outD13_13),.inB(outC12_14),.inW(w_matrix[12][13]),.outC(outC13_14),.outD(outD13_14));
PE PE13_15(.clk(clk),.rst_n(rst_n),.inA(outD13_14),.inB(outC12_15),.inW(w_matrix[12][14]),.outC(outC13_15),.outD(outD13_15));
PE PE13_16(.clk(clk),.rst_n(rst_n),.inA(outD13_15),.inB(outC12_16),.inW(w_matrix[12][15]),.outC(outC13_16),.outD(outD13_16));

PE PE14_1(.clk(clk),.rst_n(rst_n),.inA ( inA14_1),.inB( outC13_1),.inW( w_matrix[13][0]),.outC( outC14_1),.outD( outD14_1));
PE PE14_2(.clk(clk),.rst_n(rst_n),.inA( outD14_1),.inB( outC13_2),.inW( w_matrix[13][1]),.outC( outC14_2),.outD( outD14_2));
PE PE14_3(.clk(clk),.rst_n(rst_n),.inA( outD14_2),.inB( outC13_3),.inW( w_matrix[13][2]),.outC( outC14_3),.outD( outD14_3));
PE PE14_4(.clk(clk),.rst_n(rst_n),.inA( outD14_3),.inB( outC13_4),.inW( w_matrix[13][3]),.outC( outC14_4),.outD( outD14_4));
PE PE14_5(.clk(clk),.rst_n(rst_n),.inA( outD14_4),.inB( outC13_5),.inW( w_matrix[13][4]),.outC( outC14_5),.outD( outD14_5));
PE PE14_6(.clk(clk),.rst_n(rst_n),.inA( outD14_5),.inB( outC13_6),.inW( w_matrix[13][5]),.outC( outC14_6),.outD( outD14_6));
PE PE14_7(.clk(clk),.rst_n(rst_n),.inA( outD14_6),.inB( outC13_7),.inW( w_matrix[13][6]),.outC( outC14_7),.outD( outD14_7));
PE PE14_8(.clk(clk),.rst_n(rst_n),.inA( outD14_7),.inB( outC13_8),.inW( w_matrix[13][7]),.outC( outC14_8),.outD( outD14_8));
PE PE14_9 (.clk(clk),.rst_n(rst_n),.inA(outD14_8),.inB( outC13_9),.inW( w_matrix[13][8]),.outC( outC14_9 ),.outD(outD14_9 ));
PE PE14_10(.clk(clk),.rst_n(rst_n),.inA(outD14_9),.inB( outC13_10),.inW(w_matrix[13][9]),.outC( outC14_10),.outD(outD14_10));
PE PE14_11(.clk(clk),.rst_n(rst_n),.inA(outD14_10),.inB(outC13_11),.inW(w_matrix[13][10]),.outC(outC14_11),.outD(outD14_11));
PE PE14_12(.clk(clk),.rst_n(rst_n),.inA(outD14_11),.inB(outC13_12),.inW(w_matrix[13][11]),.outC(outC14_12),.outD(outD14_12));
PE PE14_13(.clk(clk),.rst_n(rst_n),.inA(outD14_12),.inB(outC13_13),.inW(w_matrix[13][12]),.outC(outC14_13),.outD(outD14_13));
PE PE14_14(.clk(clk),.rst_n(rst_n),.inA(outD14_13),.inB(outC13_14),.inW(w_matrix[13][13]),.outC(outC14_14),.outD(outD14_14));
PE PE14_15(.clk(clk),.rst_n(rst_n),.inA(outD14_14),.inB(outC13_15),.inW(w_matrix[13][14]),.outC(outC14_15),.outD(outD14_15));
PE PE14_16(.clk(clk),.rst_n(rst_n),.inA(outD14_15),.inB(outC13_16),.inW(w_matrix[13][15]),.outC(outC14_16),.outD(outD14_16));

PE PE15_1(.clk(clk),.rst_n(rst_n),.inA ( inA15_1),.inB( outC14_1),.inW( w_matrix[14][0]),.outC( outC15_1),.outD( outD15_1));
PE PE15_2(.clk(clk),.rst_n(rst_n),.inA( outD15_1),.inB( outC14_2),.inW( w_matrix[14][1]),.outC( outC15_2),.outD( outD15_2));
PE PE15_3(.clk(clk),.rst_n(rst_n),.inA( outD15_2),.inB( outC14_3),.inW( w_matrix[14][2]),.outC( outC15_3),.outD( outD15_3));
PE PE15_4(.clk(clk),.rst_n(rst_n),.inA( outD15_3),.inB( outC14_4),.inW( w_matrix[14][3]),.outC( outC15_4),.outD( outD15_4));
PE PE15_5(.clk(clk),.rst_n(rst_n),.inA( outD15_4),.inB( outC14_5),.inW( w_matrix[14][4]),.outC( outC15_5),.outD( outD15_5));
PE PE15_6(.clk(clk),.rst_n(rst_n),.inA( outD15_5),.inB( outC14_6),.inW( w_matrix[14][5]),.outC( outC15_6),.outD( outD15_6));
PE PE15_7(.clk(clk),.rst_n(rst_n),.inA( outD15_6),.inB( outC14_7),.inW( w_matrix[14][6]),.outC( outC15_7),.outD( outD15_7));
PE PE15_8(.clk(clk),.rst_n(rst_n),.inA( outD15_7),.inB( outC14_8),.inW( w_matrix[14][7]),.outC( outC15_8),.outD( outD15_8));
PE PE15_9 (.clk(clk),.rst_n(rst_n),.inA(outD15_8),.inB( outC14_9),.inW( w_matrix[14][8]),.outC( outC15_9 ),.outD(outD15_9 ));
PE PE15_10(.clk(clk),.rst_n(rst_n),.inA(outD15_9),.inB( outC14_10),.inW(w_matrix[14][9]),.outC( outC15_10),.outD(outD15_10));
PE PE15_11(.clk(clk),.rst_n(rst_n),.inA(outD15_10),.inB(outC14_11),.inW(w_matrix[14][10]),.outC(outC15_11),.outD(outD15_11));
PE PE15_12(.clk(clk),.rst_n(rst_n),.inA(outD15_11),.inB(outC14_12),.inW(w_matrix[14][11]),.outC(outC15_12),.outD(outD15_12));
PE PE15_13(.clk(clk),.rst_n(rst_n),.inA(outD15_12),.inB(outC14_13),.inW(w_matrix[14][12]),.outC(outC15_13),.outD(outD15_13));
PE PE15_14(.clk(clk),.rst_n(rst_n),.inA(outD15_13),.inB(outC14_14),.inW(w_matrix[14][13]),.outC(outC15_14),.outD(outD15_14));
PE PE15_15(.clk(clk),.rst_n(rst_n),.inA(outD15_14),.inB(outC14_15),.inW(w_matrix[14][14]),.outC(outC15_15),.outD(outD15_15));
PE PE15_16(.clk(clk),.rst_n(rst_n),.inA(outD15_15),.inB(outC14_16),.inW(w_matrix[14][15]),.outC(outC15_16),.outD(outD15_16));

PE PE16_1(.clk(clk),.rst_n(rst_n),.inA ( inA16_1),.inB( outC15_1),.inW( w_matrix[15][0]),.outC( outC16_1),.outD( outD16_1));
PE PE16_2(.clk(clk),.rst_n(rst_n),.inA( outD16_1),.inB( outC15_2),.inW( w_matrix[15][1]),.outC( outC16_2),.outD( outD16_2));
PE PE16_3(.clk(clk),.rst_n(rst_n),.inA( outD16_2),.inB( outC15_3),.inW( w_matrix[15][2]),.outC( outC16_3),.outD( outD16_3));
PE PE16_4(.clk(clk),.rst_n(rst_n),.inA( outD16_3),.inB( outC15_4),.inW( w_matrix[15][3]),.outC( outC16_4),.outD( outD16_4));
PE PE16_5(.clk(clk),.rst_n(rst_n),.inA( outD16_4),.inB( outC15_5),.inW( w_matrix[15][4]),.outC( outC16_5),.outD( outD16_5));
PE PE16_6(.clk(clk),.rst_n(rst_n),.inA( outD16_5),.inB( outC15_6),.inW( w_matrix[15][5]),.outC( outC16_6),.outD( outD16_6));
PE PE16_7(.clk(clk),.rst_n(rst_n),.inA( outD16_6),.inB( outC15_7),.inW( w_matrix[15][6]),.outC( outC16_7),.outD( outD16_7));
PE PE16_8(.clk(clk),.rst_n(rst_n),.inA( outD16_7),.inB( outC15_8),.inW( w_matrix[15][7]),.outC( outC16_8),.outD( outD16_8));
PE PE16_9 (.clk(clk),.rst_n(rst_n),.inA(outD16_8),.inB( outC15_9),.inW( w_matrix[15][8]),.outC( outC16_9 ),.outD(outD16_9 ));
PE PE16_10(.clk(clk),.rst_n(rst_n),.inA(outD16_9),.inB( outC15_10),.inW(w_matrix[15][9]),.outC( outC16_10),.outD(outD16_10));
PE PE16_11(.clk(clk),.rst_n(rst_n),.inA(outD16_10),.inB(outC15_11),.inW(w_matrix[15][10]),.outC(outC16_11),.outD(outD16_11));
PE PE16_12(.clk(clk),.rst_n(rst_n),.inA(outD16_11),.inB(outC15_12),.inW(w_matrix[15][11]),.outC(outC16_12),.outD(outD16_12));
PE PE16_13(.clk(clk),.rst_n(rst_n),.inA(outD16_12),.inB(outC15_13),.inW(w_matrix[15][12]),.outC(outC16_13),.outD(outD16_13));
PE PE16_14(.clk(clk),.rst_n(rst_n),.inA(outD16_13),.inB(outC15_14),.inW(w_matrix[15][13]),.outC(outC16_14),.outD(outD16_14));
PE PE16_15(.clk(clk),.rst_n(rst_n),.inA(outD16_14),.inB(outC15_15),.inW(w_matrix[15][14]),.outC(outC16_15),.outD(outD16_15));
PE PE16_16(.clk(clk),.rst_n(rst_n),.inA(outD16_15),.inB(outC15_16),.inW(w_matrix[15][15]),.outC(outC16_16),.outD(outD16_16));

//==============================================//
//              OUTPUT Block                    //
//==============================================//

assign c_plus = (m_size==2'b00) ? outC21+outC22 :
                (m_size==2'b01) ? outC41+outC42+outC43+outC44 : 
                (m_size==2'b10) ? outC81+outC82+outC83+outC84+outC85+outC86+outC87+outC88 : 
                (m_size==2'b11) ? outC16_1+outC16_2+outC16_3+outC16_4+outC16_5+outC16_6+outC16_7+outC16_8+outC16_9+outC16_10+outC16_11+outC16_12+outC16_13+outC16_14+outC16_15+outC16_16 : 0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_value <= 'd0;
    end
    else if(cal_cnt>=calout_cnt && out_cnt<out_cycle) begin
        out_value <= c_plus;
    end
    else begin
        out_value <= 'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 'd0;
    end
    else if(cs==CAL && cal_cnt>=calout_cnt && out_cnt<out_cycle) out_valid <= 'd1;
    else out_valid <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_cnt <= 'd0;
    end
    else if(out_valid)begin
        out_cnt <= out_cnt + 'd1;
    end
    else begin
        out_cnt <= 'd0;
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
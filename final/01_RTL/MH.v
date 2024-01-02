//synopsys translate_off
`include "DW_minmax.v"
//`include "DW_addsub_dx.v"
//synopsys translate_on

module MH(
//Connection wires
    clk,
    clk2,
    rst_n,
    in_valid,
    op_valid,
    pic_data,
    se_data,
    op,
    out_valid,
    out_data
);

// ===============================================================
//                      Parameter Declaration 
// ===============================================================

parameter IDLE          =4'd0;
parameter INPUT         =4'd1;
parameter CAL_DIL       =4'd2;
parameter TRANS         =4'd3;
parameter CAL_DIL2      =4'd4;
parameter CAL_HIS1      =4'd5;
parameter CAL_HIS2      =4'd6;
parameter EMPTY         =4'd7;
parameter OUTPUT        =4'd8;

// ===============================================================
//                      Input / Output 
// ===============================================================

input             clk,clk2,rst_n;
input             in_valid,op_valid;
input [31:0]        pic_data;     
input [7:0]        se_data;
input [2:0]         op;
output reg          out_valid;
output reg [31:0]   out_data;   


// ===============================================================
//                      Variable Declare
// ===============================================================
// ------------------------

//SRAM Declaration
parameter       BITS = 32;

wire [BITS-1:0]     Q_PIC;
reg                 WEN_PIC;
reg [7:0]           A_PIC;
reg [0:BITS-1]      D_PIC;

wire [0:31] data_sram;

reg  [3:0]ns,cs;

reg [8:0] sram_cnt; //0~255


reg [2:0]       op_reg;
reg [31:0]   pic_data_reg;     

reg  [7:0] se[0:3][0:3];
wire  [7:0] se_s[0:3][0:3];
wire [11:0] cdf_cnt [0:255];

reg [7:0] write_cnt;

reg [0:31] date_sramout;
wire [0:31] date_sramin2;

wire [12:0] cdf_bottom;
wire [21:0] cdf_top;

reg [12:0] cdf_bottom_r;
reg [21:0] cdf_top_r;

reg [7:0] cdf_f [0:255];
reg [8:0] his_cdf_cnt1;
reg [7:0] his_cdf_cnt2,his_cdf_cnt2_dly1;

reg [7:0] dil_cnt;
reg [7:0] kernal_cnt;
reg [0:31] linebuffer[0:25];

reg [7:0] cdf_min;

wire [31:0] check;
wire[1:0] ind;
wire[7:0] min;

reg [7:0] in_cnt;
reg [1:0] x_cnt;
reg [1:0] y_cnt;

reg [2:0] line_cnt; //0~7
wire [7:0] kernal[0:3][0:3][0:3];
wire signed [9:0] kernal_cal[0:3][0:3][0:3];
wire signed [9:0] kernal_caladd[0:3][0:3][0:3];
wire signed [9:0] kernal_calsub[0:3][0:3][0:3];
wire signed [9:0] kernal_dil[0:3];
wire [7:0] kernal_dil_u[0:3];
wire [31:0] data_dil;
wire min_max;

wire [159:0] check_kernal[0:3];
// ===============================================================
//                      Finite State Machine
// ===============================================================

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  cs <= IDLE;
    else    cs <= ns;
end

always@(*)begin
    if(!rst_n) ns = IDLE;
    else begin
        case(cs)
            IDLE:           ns = (in_valid)?    INPUT    :   IDLE;
            INPUT:          ns = (in_cnt=='d255) ? ((op_reg=='d0) ? CAL_HIS1 : CAL_DIL) : INPUT;
            CAL_DIL:        ns = (kernal_cnt=='d255) ? ((op_reg[2]) ? TRANS : EMPTY) : CAL_DIL;
            TRANS:          ns = CAL_DIL2;
            CAL_HIS1:       ns = (his_cdf_cnt2_dly1=='d255) ? CAL_HIS2 : CAL_HIS1;
            CAL_HIS2:       ns = (sram_cnt=='d257) ? IDLE : CAL_HIS2;
            CAL_DIL2:       ns = (sram_cnt=='d282) ?  IDLE : CAL_DIL2;
            EMPTY:          ns = OUTPUT;
            OUTPUT:         ns = (write_cnt=='d255) ? IDLE : OUTPUT;
            default:        ns = IDLE;
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  op_reg <= 'd0;
    else if(op_valid)   op_reg <= op;
    else if(ns==TRANS)  begin
        if(op_reg[0]) op_reg <= 3'b010;
        else    op_reg <= 3'b011;
    end 
    else if(ns==IDLE)   op_reg <= 'd0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  pic_data_reg <= 'd0;
    else if(in_valid)   pic_data_reg <= pic_data;
    else pic_data_reg <= 'd0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  in_cnt <= 'd0;
    else if(in_valid)   in_cnt <= in_cnt + 1;
    else in_cnt <= 'd0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  x_cnt <= 'd0;
    else if(in_valid) begin
        x_cnt <= x_cnt + 1;
    end
    else x_cnt <= 'd0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  y_cnt <= 'd0;
    else if(in_valid) begin
        if(x_cnt==3)    y_cnt <= y_cnt + 1;
    end
    else y_cnt <= 'd0;
end

integer x,y;
//data_se
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(x=0;x<4;x=x+1)
            for(y=0;y<4;y=y+1)
                se[x][y] <= 0;  
    end
    else if(in_valid && in_cnt<16)begin
        se[y_cnt][x_cnt] <= se_data;
    end
end

//se_s

assign se_s[0][0] = se[3][3];
assign se_s[0][1] = se[3][2];
assign se_s[0][2] = se[3][1];
assign se_s[0][3] = se[3][0];
assign se_s[1][0] = se[2][3];
assign se_s[1][1] = se[2][2];
assign se_s[1][2] = se[2][1];
assign se_s[1][3] = se[2][0];
assign se_s[2][0] = se[1][3];
assign se_s[2][1] = se[1][2];
assign se_s[2][2] = se[1][1];
assign se_s[2][3] = se[1][0];
assign se_s[3][0] = se[0][3];
assign se_s[3][1] = se[0][2];
assign se_s[3][2] = se[0][1];
assign se_s[3][3] = se[0][0];

// ===============================================================
//                      DILATION
// ===============================================================

wire [0:31] linebuffer_in;

assign linebuffer_in = (cs==CAL_DIL2) ? date_sramout : data_sram ;
integer a;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(a=0;a<25;a=a+1)
            linebuffer[a] <= 'd0;
    end
    else begin
        linebuffer[0 ] <= linebuffer_in;
        linebuffer[1 ] <= linebuffer[0 ];
        linebuffer[2 ] <= linebuffer[1 ];
        linebuffer[3 ] <= linebuffer[2 ];
        linebuffer[4 ] <= linebuffer[3 ];
        linebuffer[5 ] <= linebuffer[4 ];
        linebuffer[6 ] <= linebuffer[5 ];
        linebuffer[7 ] <= linebuffer[6 ];
        linebuffer[8 ] <= linebuffer[7 ];
        linebuffer[9 ] <= linebuffer[8 ];
        linebuffer[10] <= linebuffer[9 ];
        linebuffer[11] <= linebuffer[10];
        linebuffer[12] <= linebuffer[11];
        linebuffer[13] <= linebuffer[12];
        linebuffer[14] <= linebuffer[13];
        linebuffer[15] <= linebuffer[14];
        linebuffer[16] <= linebuffer[15];
        linebuffer[17] <= linebuffer[16];
        linebuffer[18] <= linebuffer[17];
        linebuffer[19] <= linebuffer[18];
        linebuffer[20] <= linebuffer[19];
        linebuffer[21] <= linebuffer[20];
        linebuffer[22] <= linebuffer[21];
        linebuffer[23] <= linebuffer[22];
        linebuffer[24] <= linebuffer[23];
        linebuffer[25] <= linebuffer[24];
    end
end

assign min_max = (op_reg[0]) ? 1'b1 : 1'b0; //   1:dilation+max     0:erosion-min

wire[3:0] ind_k[0:3];
genvar m,n;
generate
    for (m = 0; m < 4; m = m + 1) begin:m_loop
        for (n = 0; n < 4; n = n + 1) begin:n_loop
            assign kernal[0][m][n] = linebuffer[25-(8*m)][(n*8) +:8];
            assign kernal_caladd[0][m][n] = kernal[0][m][n] + se_s[m][n];
            assign kernal_calsub[0][m][n] = kernal[0][m][n] - se[m][n];
            assign kernal_cal[0][m][n] = (op_reg[0]) ? kernal_caladd[0][m][n] : kernal_calsub[0][m][n] ;
        end
    end
    assign check_kernal[0] = {  kernal_cal[0][0][0],kernal_cal[0][0][1],kernal_cal[0][0][2],kernal_cal[0][0][3],
                                kernal_cal[0][1][0],kernal_cal[0][1][1],kernal_cal[0][1][2],kernal_cal[0][1][3],
                                kernal_cal[0][2][0],kernal_cal[0][2][1],kernal_cal[0][2][2],kernal_cal[0][2][3],
                                kernal_cal[0][3][0],kernal_cal[0][3][1],kernal_cal[0][3][2],kernal_cal[0][3][3]
                            };
    DW_minmax #(10,16) Max_add( .a(check_kernal[0]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[0]), .index(ind_k[0]) );
    assign kernal_dil_u[0] = (op_reg[0])  ? (kernal_dil[0]>'d255)? 'd255 : kernal_dil[0][7:0]
                                        : (kernal_dil[0][8])? 'd0 : kernal_dil[0][7:0];
endgenerate

genvar m13,n13;
generate
    for (m13 = 0; m13 < 4; m13 = m13 + 1) begin:m13_loop
        for (n13 = 0; n13 < 3; n13 = n13 + 1) begin:n13_loop
            assign kernal[1][m13][n13] = linebuffer[25-(8*m13)][((n13*8)+8) +:8];
            assign kernal_caladd[1][m13][n13] = kernal[1][m13][n13] + se_s[m13][n13];
            assign kernal_calsub[1][m13][n13] = kernal[1][m13][n13] - se[m13][n13];
            assign kernal_cal[1][m13][n13] = (op_reg[0]) ? kernal_caladd[1][m13][n13] : kernal_calsub[1][m13][n13] ;
        end
        assign kernal[1][m13][3]           = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m13)][0:7];
        assign kernal_caladd[1][m13][3]    = kernal[1][m13][3] + se_s[m13][3];
        assign kernal_calsub[1][m13][3]    = kernal[1][m13][3] - se[m13][3];
        assign kernal_cal[1][m13][3]       = (op_reg[0]) ? kernal_caladd[1][m13][3] : kernal_calsub[1][m13][3] ;
    end
endgenerate

assign check_kernal[1] = {  kernal_cal[1][0][0],kernal_cal[1][0][1],kernal_cal[1][0][2],kernal_cal[1][0][3],
                            kernal_cal[1][1][0],kernal_cal[1][1][1],kernal_cal[1][1][2],kernal_cal[1][1][3],
                            kernal_cal[1][2][0],kernal_cal[1][2][1],kernal_cal[1][2][2],kernal_cal[1][2][3],
                            kernal_cal[1][3][0],kernal_cal[1][3][1],kernal_cal[1][3][2],kernal_cal[1][3][3]
                        };
DW_minmax #(10,16) Max_add13( .a(check_kernal[1]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[1]), .index(ind_k[1]) );

assign kernal_dil_u[1] = (op_reg[0])  ? (kernal_dil[1]>'d255)? 'd255 : kernal_dil[1][7:0]
                                            : (kernal_dil[1][8])? 'd0 : kernal_dil[1][7:0];

genvar m14,n14;
generate
    for (m14 = 0; m14 < 4; m14 = m14 + 1) begin:m14_loop
        for (n14 = 0; n14 < 2; n14 = n14 + 1) begin:n14_loop
            assign kernal[2][m14][n14] = linebuffer[25-(8*m14)][((n14*8)+16) +:8];
            assign kernal_caladd[2][m14][n14] = kernal[2][m14][n14] + se_s[m14][n14];
            assign kernal_calsub[2][m14][n14] = kernal[2][m14][n14] - se[m14][n14];
            assign kernal_cal[2][m14][n14] = (op_reg[0]) ? kernal_caladd[2][m14][n14] : kernal_calsub[2][m14][n14] ;
        end
        assign kernal[2][m14][2] = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m14)][0:7];
        assign kernal[2][m14][3] = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m14)][8:15];
        assign kernal_caladd[2][m14][2] = kernal[2][m14][2] + se_s[m14][2];
        assign kernal_caladd[2][m14][3] = kernal[2][m14][3] + se_s[m14][3];
        assign kernal_calsub[2][m14][2] = kernal[2][m14][2] - se[m14][2];
        assign kernal_calsub[2][m14][3] = kernal[2][m14][3] - se[m14][3];
        assign kernal_cal[2][m14][2] = (op_reg[0]) ? kernal_caladd[2][m14][2] : kernal_calsub[2][m14][2] ;
        assign kernal_cal[2][m14][3] = (op_reg[0]) ? kernal_caladd[2][m14][3] : kernal_calsub[2][m14][3] ;
    end
endgenerate

assign check_kernal[2] = {  kernal_cal[2][0][0],kernal_cal[2][0][1],kernal_cal[2][0][2],kernal_cal[2][0][3],
                            kernal_cal[2][1][0],kernal_cal[2][1][1],kernal_cal[2][1][2],kernal_cal[2][1][3],
                            kernal_cal[2][2][0],kernal_cal[2][2][1],kernal_cal[2][2][2],kernal_cal[2][2][3],
                            kernal_cal[2][3][0],kernal_cal[2][3][1],kernal_cal[2][3][2],kernal_cal[2][3][3]
                        };
DW_minmax #(10,16) Max_add14( .a(check_kernal[2]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[2]), .index(ind_k[2]) );

assign kernal_dil_u[2] = (op_reg[0])  ? (kernal_dil[2]>'d255)? 'd255 : kernal_dil[2][7:0]
                                            : (kernal_dil[2][8])? 'd0 : kernal_dil[2][7:0];

genvar m15;
generate
    for (m15 = 0; m15 < 4; m15 = m15 + 1) begin:m15_loop
        assign kernal[3][m15][0] = linebuffer[25-(8*m15)][24 +:8];
        assign kernal[3][m15][1] = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m15)][0:7];
        assign kernal[3][m15][2] = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m15)][8:15];
        assign kernal[3][m15][3] = (line_cnt=='d7) ? 'd0 : linebuffer[24-(8*m15)][16:23];

        assign kernal_caladd[3][m15][0] = kernal[3][m15][0] + se_s[m15][0];
        assign kernal_caladd[3][m15][1] = kernal[3][m15][1] + se_s[m15][1];
        assign kernal_caladd[3][m15][2] = kernal[3][m15][2] + se_s[m15][2];
        assign kernal_caladd[3][m15][3] = kernal[3][m15][3] + se_s[m15][3];

        assign kernal_calsub[3][m15][0] = kernal[3][m15][0] - se[m15][0];
        assign kernal_calsub[3][m15][1] = kernal[3][m15][1] - se[m15][1];
        assign kernal_calsub[3][m15][2] = kernal[3][m15][2] - se[m15][2];
        assign kernal_calsub[3][m15][3] = kernal[3][m15][3] - se[m15][3];

        assign kernal_cal[3][m15][0] = (op_reg[0]) ? kernal_caladd[3][m15][0] : kernal_calsub[3][m15][0] ;
        assign kernal_cal[3][m15][1] = (op_reg[0]) ? kernal_caladd[3][m15][1] : kernal_calsub[3][m15][1] ;
        assign kernal_cal[3][m15][2] = (op_reg[0]) ? kernal_caladd[3][m15][2] : kernal_calsub[3][m15][2] ;
        assign kernal_cal[3][m15][3] = (op_reg[0]) ? kernal_caladd[3][m15][3] : kernal_calsub[3][m15][3] ;
    end
endgenerate

assign check_kernal[3] = {  kernal_cal[3][0][0],kernal_cal[3][0][1],kernal_cal[3][0][2],kernal_cal[3][0][3],
                             kernal_cal[3][1][0],kernal_cal[3][1][1],kernal_cal[3][1][2],kernal_cal[3][1][3],
                             kernal_cal[3][2][0],kernal_cal[3][2][1],kernal_cal[3][2][2],kernal_cal[3][2][3],
                             kernal_cal[3][3][0],kernal_cal[3][3][1],kernal_cal[3][3][2],kernal_cal[3][3][3]
                        };
DW_minmax #(10,16) Max_add15( .a(check_kernal[3]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[3]), .index(ind_k[3]) );

assign kernal_dil_u[3] = (op_reg[0])  ? (kernal_dil[3]>'d255)? 'd255 : kernal_dil[3][7:0]
                                            : (kernal_dil[3][8])? 'd0 : kernal_dil[3][7:0];

assign data_dil = { kernal_dil_u[3],kernal_dil_u[2],  kernal_dil_u[1], kernal_dil_u[0] };

reg dil2_flag,dil2_flag_dly1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dil2_flag <= 'd0;
    end
    else if(cs==CAL_DIL2)
        dil2_flag <= 'd1;
    else  dil2_flag<= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dil2_flag_dly1 <= 'd0;
    end
    else begin
        dil2_flag_dly1<= dil2_flag;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dil_cnt <= 'd0;
    end
    else if(cs==INPUT)begin
        dil_cnt <= dil_cnt + 1;
    end
    else if(cs==CAL_DIL2 && dil2_flag)
        dil_cnt <= dil_cnt + 1;
    else  dil_cnt<= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kernal_cnt <= 'd0;
    end
    else if(dil_cnt>'d25 || cs==CAL_DIL)begin
        kernal_cnt <= kernal_cnt + 1;
    end
    else  kernal_cnt <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        line_cnt <= 'd0;
    end
    else if(dil_cnt>'d25 || cs==CAL_DIL)begin
        line_cnt <= line_cnt + 1;
    end
    else  line_cnt <= 'b0;
end


/*
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         <= 'd0;
    end
    else if()begin
         <= ;
    end
    else  <= 'b0;
end
*/
/*
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         <= 'd0;
    end
    else if()begin
         <= ;
    end
    else  <= 'b0;
end
*/
// ===============================================================
//                      SRAM 
// ===============================================================

SRAM_256_32 PIC(.Q(Q_PIC), .CLK(clk), .CEN(1'b0), .WEN(WEN_PIC), .A(A_PIC), .D(D_PIC), .OEN(1'b0));

//WEN_PIC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WEN_PIC <= 'd1;
    end
    else if(in_valid || cs==INPUT)begin
        WEN_PIC <= 'b0; //write
    end
    else if(ns==CAL_DIL)
        WEN_PIC <= 'b0;
    else if(ns==CAL_HIS2 || ns==CAL_DIL2)
        WEN_PIC <= 'b1;
    else 
        WEN_PIC <= 'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_cnt <= 0;
    end
    else if(cs==INPUT)begin
        sram_cnt <= sram_cnt + 'd1;
    end
    else if(cs==CAL_HIS2)begin
        sram_cnt <= sram_cnt + 'd1;
    end
    else if(cs==CAL_DIL2)
        sram_cnt <= sram_cnt + 1;
    else begin
        sram_cnt <= 0;
    end
end


//A_PIC
always @(*) begin
    case(cs)
        INPUT: begin
            if(!op_reg[1])
                A_PIC = sram_cnt;
            else
                A_PIC = kernal_cnt;
        end
        CAL_DIL:
            A_PIC = kernal_cnt;
        CAL_HIS1:
            A_PIC = sram_cnt;
        CAL_HIS2:
            A_PIC = sram_cnt + 1 ;
        CAL_DIL2:
            A_PIC = sram_cnt + 1 ;
        OUTPUT:
            A_PIC =  write_cnt + 1;
        default:
            A_PIC = 0;
    endcase
end

assign data_sram = {pic_data_reg[7:0],pic_data_reg[15:8],pic_data_reg[23:16],pic_data_reg[31:24]};

//D_PIC

always @(*) begin
    case(cs)
        INPUT:
            if(!op_reg[1])
                D_PIC = data_sram;
            else if(op_reg[2])
                D_PIC = {data_dil[7:0],data_dil[15:8],data_dil[23:16],data_dil[31:24]};
            else
                D_PIC = data_dil;
        CAL_DIL: begin
            if(op_reg[2]) begin
                D_PIC = {data_dil[7:0],data_dil[15:8],data_dil[23:16],data_dil[31:24]};
            end
            else begin
                D_PIC = data_dil;
            end
        end
        CAL_HIS1:
            D_PIC = data_sram;
        default:
            D_PIC = 0;
    endcase
end

//Q_PIC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        date_sramout <= 0;
    end
    else begin
        case(cs)
            CAL_HIS2:
                date_sramout <= Q_PIC;
            CAL_DIL2: begin
                if(sram_cnt>255)    date_sramout <= 0;
                else    date_sramout <= Q_PIC;
            end
            default:
                date_sramout <= 0;
        endcase
    end
end


// ===============================================================
//                      HISTOGRAM
// ===============================================================

wire pixel [0:3][0:255] ;

genvar p;
generate
    for (p = 0; p < 256; p = p + 1) begin : loop_pixel
        assign pixel[0 ][p] =  (p >= pic_data[7:0]    ) ? 1'b1 : 1'b0;
        assign pixel[1 ][p] =  (p >= pic_data[15:8]   ) ? 1'b1 : 1'b0;
        assign pixel[2 ][p] =  (p >= pic_data[23:16]  ) ? 1'b1 : 1'b0;
        assign pixel[3 ][p] =  (p >= pic_data[31:24]  ) ? 1'b1 : 1'b0;
    end
endgenerate

genvar q;
generate
    for (q = 0; q < 256; q = q + 1) begin : loop_cnt
        assign cdf_cnt[q] =  pixel[0 ][q] + pixel[1 ][q] + pixel[2 ][q] + pixel[3 ][q];
    end
endgenerate


reg [12:0] cdf_add [0:255] ;

genvar j;
generate
    for (j = 0; j < 256; j = j + 1) begin : loop_addcdf
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                cdf_add[j] <= 'd0;
            end
            else if(in_valid || cs==INPUT) begin
                cdf_add[j] <= cdf_cnt[j] + cdf_add[j] ;
            end
            else if(ns==IDLE) cdf_add[j] <= 'd0;
        end
    end
endgenerate

assign check = {pic_data[7:0], 
                pic_data[15:8],
                pic_data[23:16] ,
                pic_data[31:24]
                };

DW_minmax #(8,4) Min_u ( .a(check), .tc(1'b0), .min_max(1'b0), .value(min), .index(ind) );

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         cdf_min <= 'd255;
    end
    else if(in_valid || cs==INPUT)begin
        if(min < cdf_min)
            cdf_min <= min;
    end
    else if(ns==IDLE)
        cdf_min <= 'd255;
end

assign cdf_bottom = (cdf_add[255] - cdf_add[cdf_min]) ;
assign cdf_top = (cdf_add[his_cdf_cnt2]-cdf_add[cdf_min]);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         cdf_bottom_r <= 'd0;
    end
    else 
        cdf_bottom_r <= cdf_bottom;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         cdf_top_r <= 'd0;
    end
    else 
        cdf_top_r <= ((cdf_top<<8) -cdf_top);
end

integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i=0;i<256;i=i+1)
            cdf_f[i] <= 'd0;
    end
    else if(cs == CAL_HIS1) begin
        cdf_f[his_cdf_cnt2_dly1] <= cdf_top_r / cdf_bottom_r ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        his_cdf_cnt1<= 'd0;
    end
    else if(cs==INPUT)begin
        if(his_cdf_cnt1==255)   his_cdf_cnt1 <= his_cdf_cnt1;
        else    his_cdf_cnt1<= his_cdf_cnt1 + 'd1;
    end
    else if(ns==IDLE) his_cdf_cnt1<= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        his_cdf_cnt2<= 'd0;
    end
    else if(his_cdf_cnt1==255)begin
        his_cdf_cnt2<= his_cdf_cnt2 + 'd1;
    end
    else his_cdf_cnt2<= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        his_cdf_cnt2_dly1<= 'd0;
    end
    else his_cdf_cnt2_dly1 <= his_cdf_cnt2;
end

reg [0:7] result0 ;
reg [0:7] result1 ;
reg [0:7] result2 ;
reg [0:7] result3 ;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result0  <= 'd0;
        result1  <= 'd0;
        result2  <= 'd0;
        result3  <= 'd0; 
    end
    else if(cs == CAL_HIS2) begin
        result0 <= cdf_f[date_sramout[24 :31]];
        result1 <= cdf_f[date_sramout[16:23]];
        result2 <= cdf_f[date_sramout[8:15]];
        result3 <= cdf_f[date_sramout[0:7]];
    end
end

assign date_sramin2 = {result0,result1,result2,result3};


//OUTPUT
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 'd0;
    end
    else if(cs==CAL_HIS2) begin
        if(sram_cnt>1)  out_valid <= 'd1;
        else    out_valid <= 'd0;
    end
    else if(cs==OUTPUT) begin
        out_valid <= 'd1;
    end
    else if(cs==CAL_DIL2) begin
        if(sram_cnt>26)  out_valid <= 'd1;
        else    out_valid <= 'd0;
    end
    else out_valid <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 'd0;
    end
    else if(cs== CAL_HIS2) begin
        if(sram_cnt>1)
            out_data <= date_sramin2;
        else 
            out_data <= 'd0;
    end
    else if(cs==OUTPUT) begin
        out_data <= Q_PIC;
    end
    else if(cs==CAL_DIL2)
        if(sram_cnt>26)
            out_data <= data_dil;
        else
            out_data <= 'd0;
    else out_data <= 'b0;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_cnt <= 0;
    end
    else if(cs == OUTPUT)begin
        write_cnt <= write_cnt + 'd1;
    end
    else begin
        write_cnt <= 0;
    end
end


endmodule
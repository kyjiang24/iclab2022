//synopsys translate_off
`include "DW_minmax.v"
//`include "DW_addsub_dx.v"
//synopsys translate_on

module EDH(
//Connection wires
    clk,
    rst_n,
    in_valid,
    op,
    pic_no,
    se_no,
    busy,

// axi write address channel 
       awid_m_inf,
     awaddr_m_inf,
     awsize_m_inf,
    awburst_m_inf,
      awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,
// axi write data channel 
      wdata_m_inf,
      wlast_m_inf,
     wvalid_m_inf,
     wready_m_inf,
// axi write response channel
       bid_m_inf,
     bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf,
// -----------------------------
// axi read address channel 
       arid_m_inf,
     araddr_m_inf,
      arlen_m_inf,
     arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,
// -----------------------------
// axi read data channel 
       rid_m_inf,
     rdata_m_inf,
     rresp_m_inf,
     rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf,
// -----------------------------
);

// ===============================================================
//                      Parameter Declaration 
// ===============================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 128;


parameter IDLE          =4'd0;
parameter READ_SE_ADDR  =4'd1;
parameter READ_SE       =4'd2;
parameter READ_PIC_ADDR =4'd3;
parameter READ_PIC      =4'd4;
parameter CAL_DIL       =4'd5;
parameter CAL_HIS1      =4'd6;
parameter CAL_HIS2      =4'd7;
parameter WRITE_ADDR    =4'd8;
parameter WRITE         =4'd9;
// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
input             clk,rst_n;
input             in_valid;
input [1:0]           op;
input [3:0]        pic_no;     
input [5:0]        se_no;     
output reg          busy;          


// ===============================================================
//                      Variable Declare
// ===============================================================
// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)  axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output reg [7:0]              arlen_m_inf;
output reg                  arvalid_m_inf;
input  wire                  arready_m_inf;
output reg [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)  axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output reg                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1)  axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output reg [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)  axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
// -------------------------
// (3)  axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------
reg rlast_reg,rvalid_reg;

//SRAM Declaration
parameter       BITS = 128;

wire [BITS-1:0]     Q_PIC,Q_PIC2;
reg                 WEN_PIC,WEN_PIC2;
reg [7:0]           A_PIC,A_PIC2;
reg [0:BITS-1]      D_PIC,D_PIC2;



reg [127:0] data_dram;
wire [0:127] data_sram;

reg  [3:0]ns,cs;

reg [8:0] sram_cnt; //0~255


reg [1:0]       op_reg;
reg [3:0]   pic_no_reg;     
reg [5:0]    se_no_reg;   

reg  [7:0] se[0:3][0:3];
wire  [7:0] se_s[0:3][0:3];
wire [11:0] cdf_cnt [0:255];

reg [7:0] write_cnt;

reg [0:127] date_sramout;
wire [0:127] date_sramin2;

wire [12:0] cdf_bottom;
wire [21:0] cdf_top;

reg [12:0] cdf_bottom_r;
reg [21:0] cdf_top_r;

reg [7:0] cdf_f [0:255];
reg [8:0] his_cdf_cnt1;
reg [7:0] his_cdf_cnt2,his_cdf_cnt2_dly1;

reg [7:0] dil_cnt;
reg [7:0] kernal_cnt;
reg [0:127] linebuffer[0:13];

reg [7:0] cdf_min;

wire [127:0] check;
wire[3:0] ind;
wire[7:0] min;
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
            IDLE:           ns = (in_valid)?    READ_SE_ADDR    :   IDLE;
            READ_SE_ADDR:   ns = (arready_m_inf) ? READ_SE : READ_SE_ADDR;
            READ_SE:        ns = (rlast_reg) ? READ_PIC_ADDR : READ_SE;
            READ_PIC_ADDR:  ns = (arready_m_inf) ? READ_PIC : READ_PIC_ADDR;
            READ_PIC:       ns = (rlast_reg==0) ? READ_PIC : (op_reg=='d2) ? CAL_HIS1 :  CAL_DIL;
            CAL_DIL:        ns = (kernal_cnt=='d255) ? WRITE_ADDR : CAL_DIL;
            CAL_HIS1:       ns = (his_cdf_cnt2_dly1=='d255) ? CAL_HIS2 : CAL_HIS1;
            CAL_HIS2:       ns = (sram_cnt=='d258) ? WRITE_ADDR : CAL_HIS2;
            WRITE_ADDR:     ns = (awready_m_inf) ? WRITE : WRITE_ADDR;
            WRITE:          ns = (bresp_m_inf==2'b0&&bvalid_m_inf) ? IDLE : WRITE;
            default:        ns = IDLE;
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  op_reg <= 'd0;
    else if(in_valid)   op_reg <= op;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  pic_no_reg <= 'd0;
    else if(in_valid)   pic_no_reg <= pic_no;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  se_no_reg <= 'd0;
    else if(in_valid)   se_no_reg <= se_no;
end


// ===============================================================
//                      AXI4 Interfaces
// ===============================================================
//////////////////////////////////////////////
//              Read Address                //
//////////////////////////////////////////////

assign arid_m_inf = 4'd0;           // fixed id to 0 
assign arburst_m_inf = 2'd1;        // fixed mode to INCR mode 
assign arsize_m_inf = 3'b100;       // fixed size to 2^4 = 16 Bytes 
//assign arlen_m_inf = (cs==READ_SE_ADDR) ? 8'd63 : 8'd255;
//assign araddr_m_inf = (cs==READ_PIC_ADDR) ? 32'h0004_0000 + (pic_no_reg<<12) : 32'h0003_0000;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        arlen_m_inf <= 0;
    end
    else begin
        if(cs == READ_PIC_ADDR) begin
            arlen_m_inf <= 8'd255;
        end
        else begin
            arlen_m_inf <= 8'd0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        araddr_m_inf <= 0;
    end
    else begin
        if(cs == READ_PIC_ADDR) begin
            araddr_m_inf <= 32'h0004_0000 + (pic_no_reg<<12);
        end
        else begin
            araddr_m_inf <= 32'h0003_0000 + (se_no_reg<<4);
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        arvalid_m_inf <= 0;
    end
    else begin
        case(cs)
            READ_SE_ADDR:
                if(arready_m_inf)
                    arvalid_m_inf <= 0;
                else
                    arvalid_m_inf <= 1;
            READ_PIC_ADDR:
                if(arready_m_inf)
                    arvalid_m_inf <= 0;
                else
                    arvalid_m_inf <= 1;
            default:
                arvalid_m_inf <= 0;
        endcase
    end
end

//////////////////////////////////////////////
//                Read Data                ///
//////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rready_m_inf <= 0;
    end
    else begin
        case(cs)
            READ_SE:
                rready_m_inf <= 1;
            READ_PIC:
                rready_m_inf <= 1;
            default:
                rready_m_inf <= 0;     
        endcase
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  rlast_reg <= 'd0;
    else if (cs==READ_SE || cs==READ_PIC)   
        rlast_reg <= rlast_m_inf;
    else begin
        rlast_reg <= 'd0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  rvalid_reg <= 'd0;
    else if(cs==READ_SE || cs==READ_PIC)
        rvalid_reg <= rvalid_m_inf;
    else 
        rvalid_reg <= 'd0;
end

//data_dram
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_dram <= 0;
    end
    else begin
        case(cs)
            READ_PIC: begin
                if(rvalid_m_inf)
                    data_dram <= rdata_m_inf;
                else data_dram <= 0;
            end
            default : data_dram <= 0;
        endcase
    end
end

assign data_sram = {data_dram[7:0],data_dram[15:8],data_dram[23:16],data_dram[31:24],data_dram[39:32],data_dram[47:40],data_dram[55:48],data_dram[63:56],data_dram[71:64],data_dram[79:72],data_dram[87:80],data_dram[95:88],data_dram[103:96],data_dram[111:104],data_dram[119:112],data_dram[127:120]};

integer x,y;
//data_se
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(x=0;x<4;x=x+1)
            for(y=0;y<4;y=y+1)
                se[x][y] <= 0;  
    end
    else begin
        case(cs)
            READ_SE: begin
                if(rvalid_m_inf) begin
                    se[0][0] <= rdata_m_inf[7:0];
                    se[0][1] <= rdata_m_inf[15:8];
                    se[0][2] <= rdata_m_inf[23:16];
                    se[0][3] <= rdata_m_inf[31:24];
                    se[1][0] <= rdata_m_inf[39:32];
                    se[1][1] <= rdata_m_inf[47:40];
                    se[1][2] <= rdata_m_inf[55:48];
                    se[1][3] <= rdata_m_inf[63:56];
                    se[2][0] <= rdata_m_inf[71:64];
                    se[2][1] <= rdata_m_inf[79:72];
                    se[2][2] <= rdata_m_inf[87:80];
                    se[2][3] <= rdata_m_inf[95:88];
                    se[3][0] <= rdata_m_inf[103:96];
                    se[3][1] <= rdata_m_inf[111:104];
                    se[3][2] <= rdata_m_inf[119:112];
                    se[3][3] <= rdata_m_inf[127:120];
                end
            end
        endcase
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

/////////////////////////////////////////////
//              Write Response              //
//////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        busy <= 'd0;
    end
    else if(ns==IDLE || in_valid)begin
        busy <= 'b0;
    end
    else busy <= 'b1;
end

//////////////////////////////////////////////
//              Write Address               //
//////////////////////////////////////////////

//awvalid_r
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        awvalid_m_inf <= 0;
    end
    else begin
        case(cs)
            WRITE_ADDR:
                if(awready_m_inf)
                    awvalid_m_inf <= 0;
                else
                    awvalid_m_inf <= 1;           
            default:
                awvalid_m_inf <= 0;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        awaddr_m_inf <= 0;
    end
    else begin
        case(cs)
            WRITE_ADDR:
                if(awready_m_inf)
                    awaddr_m_inf <= 0;
                else
                    awaddr_m_inf <= 32'h0004_0000 + (pic_no_reg<<12);
            default:
                awaddr_m_inf <= 0;
        endcase
    end
end


assign awid_m_inf = 'd0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 3'b100;
assign awlen_m_inf = (cs== WRITE_ADDR) ? 'd255 : 'd0;

//////////////////////////////////////////////
//                Write Data                //
//////////////////////////////////////////////
/*
//wdata_r
always @(*) begin
    case(cs)
        WRITE:
            wdata_m_inf <= Q_PIC2;
        default:
            wdata_m_inf <= 0;
    endcase
end
*/

assign wdata_m_inf = Q_PIC2;

//wlast_r
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wlast_m_inf <= 0;
    end
    else begin
        case(cs)
            WRITE:
                if(write_cnt==254)
                    wlast_m_inf <= 1;
                else
                    wlast_m_inf <= 0;
        endcase
    end
end

//wvalid_r
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wvalid_m_inf <= 0;
    end
    else begin
        case(cs)
            WRITE:
                if(write_cnt<255)
                    wvalid_m_inf <= 1;
                else
                    wvalid_m_inf <= 0;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_cnt <= 0;
    end
    else if(cs == WRITE)begin
        if(wready_m_inf&&wvalid_m_inf)
            write_cnt <= write_cnt + 'd1;
    end
    else begin
        write_cnt <= 0;
    end
end

//bready_r
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bready_m_inf <= 0;
    end
    else begin
        case(ns)
            WRITE:
                if(bvalid_m_inf)
                    bready_m_inf<=0;
                else
                    bready_m_inf<=1;

        endcase
    end
end
// ===============================================================
//                      DILATION
// ===============================================================



integer a;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(a=0;a<14;a=a+1)
            linebuffer[a] <= 'd0;
    end
    else begin
        linebuffer[0 ] <= data_sram;
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
    end
end


reg [1:0] line_cnt;
wire [7:0] kernal[0:15][0:3][0:3];
wire signed [9:0] kernal_cal[0:15][0:3][0:3];
wire signed [9:0] kernal_caladd[0:15][0:3][0:3];
wire signed [9:0] kernal_calsub[0:15][0:3][0:3];
wire signed [9:0] kernal_dil[0:15];
wire [7:0] kernal_dil_u[0:15];
wire [127:0] data_dil;
wire min_max;

wire [159:0] check_kernal[0:15];

assign min_max = (op_reg==1) ? 1'b1 : 1'b0;

wire[3:0] ind_k[0:15];
genvar m,n,k;
generate
     for (k = 0; k < 13; k = k + 1) begin:k_loop
        for (m = 0; m < 4; m = m + 1) begin:m_loop
            for (n = 0; n < 4; n = n + 1) begin:n_loop
                assign kernal[k][m][n] = linebuffer[13-(4*m)][((n*8)+(k*8)) +:8];
                assign kernal_caladd[k][m][n] = kernal[k][m][n] + se_s[m][n];
                assign kernal_calsub[k][m][n] = kernal[k][m][n] - se[m][n];
                assign kernal_cal[k][m][n] = (op_reg==1) ? kernal_caladd[k][m][n] : kernal_calsub[k][m][n] ;
            end
        end

        assign check_kernal[k] = {  kernal_cal[k][0][0],kernal_cal[k][0][1],kernal_cal[k][0][2],kernal_cal[k][0][3],
                                    kernal_cal[k][1][0],kernal_cal[k][1][1],kernal_cal[k][1][2],kernal_cal[k][1][3],
                                    kernal_cal[k][2][0],kernal_cal[k][2][1],kernal_cal[k][2][2],kernal_cal[k][2][3],
                                    kernal_cal[k][3][0],kernal_cal[k][3][1],kernal_cal[k][3][2],kernal_cal[k][3][3]
                                };
        DW_minmax #(10,16) Max_add( .a(check_kernal[k]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[k]), .index(ind_k[k]) );

        assign kernal_dil_u[k] = (op_reg==1)  ? (kernal_dil[k]>'d255)? 'd255 : kernal_dil[k][7:0]
                                            : (kernal_dil[k][8])? 'd0 : kernal_dil[k][7:0];
    end
endgenerate

genvar m13,n13;
generate
    for (m13 = 0; m13 < 4; m13 = m13 + 1) begin:m13_loop
        for (n13 = 0; n13 < 3; n13 = n13 + 1) begin:n13_loop
            assign kernal[13][m13][n13] = linebuffer[13-(4*m13)][((n13*8)+104) +:8];
            assign kernal_caladd[13][m13][n13] = kernal[13][m13][n13] + se_s[m13][n13];
            assign kernal_calsub[13][m13][n13] = kernal[13][m13][n13] - se[m13][n13];
            assign kernal_cal[13][m13][n13] = (op_reg==1) ? kernal_caladd[13][m13][n13] : kernal_calsub[13][m13][n13] ;
        end
        assign kernal[13][m13][3]           = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m13)][0:7];
        assign kernal_caladd[13][m13][3]    = kernal[13][m13][3] + se_s[m13][3];
        assign kernal_calsub[13][m13][3]    = kernal[13][m13][3] - se[m13][3];
        assign kernal_cal[13][m13][3]       = (op_reg==1) ? kernal_caladd[13][m13][3] : kernal_calsub[13][m13][3] ;
    end
endgenerate

assign check_kernal[13] = {  kernal_cal[13][0][0],kernal_cal[13][0][1],kernal_cal[13][0][2],kernal_cal[13][0][3],
                             kernal_cal[13][1][0],kernal_cal[13][1][1],kernal_cal[13][1][2],kernal_cal[13][1][3],
                             kernal_cal[13][2][0],kernal_cal[13][2][1],kernal_cal[13][2][2],kernal_cal[13][2][3],
                             kernal_cal[13][3][0],kernal_cal[13][3][1],kernal_cal[13][3][2],kernal_cal[13][3][3]
                        };
DW_minmax #(10,16) Max_add13( .a(check_kernal[13]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[13]), .index(ind_k[13]) );

assign kernal_dil_u[13] = (op_reg==1)  ? (kernal_dil[13]>'d255)? 'd255 : kernal_dil[13][7:0]
                                            : (kernal_dil[13][8])? 'd0 : kernal_dil[13][7:0];

genvar m14,n14;
generate
    for (m14 = 0; m14 < 4; m14 = m14 + 1) begin:m14_loop
        for (n14 = 0; n14 < 2; n14 = n14 + 1) begin:n14_loop
            assign kernal[14][m14][n14] = linebuffer[13-(4*m14)][((n14*8)+112) +:8];
            assign kernal_caladd[14][m14][n14] = kernal[14][m14][n14] + se_s[m14][n14];
            assign kernal_calsub[14][m14][n14] = kernal[14][m14][n14] - se[m14][n14];
            assign kernal_cal[14][m14][n14] = (op_reg==1) ? kernal_caladd[14][m14][n14] : kernal_calsub[14][m14][n14] ;
        end
        assign kernal[14][m14][2] = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m14)][0:7];
        assign kernal[14][m14][3] = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m14)][8:15];
        assign kernal_caladd[14][m14][2] = kernal[14][m14][2] + se_s[m14][2];
        assign kernal_caladd[14][m14][3] = kernal[14][m14][3] + se_s[m14][3];
        assign kernal_calsub[14][m14][2] = kernal[14][m14][2] - se[m14][2];
        assign kernal_calsub[14][m14][3] = kernal[14][m14][3] - se[m14][3];
        assign kernal_cal[14][m14][2] = (op_reg==1) ? kernal_caladd[14][m14][2] : kernal_calsub[14][m14][2] ;
        assign kernal_cal[14][m14][3] = (op_reg==1) ? kernal_caladd[14][m14][3] : kernal_calsub[14][m14][3] ;
    end
endgenerate

assign check_kernal[14] = {  kernal_cal[14][0][0],kernal_cal[14][0][1],kernal_cal[14][0][2],kernal_cal[14][0][3],
                             kernal_cal[14][1][0],kernal_cal[14][1][1],kernal_cal[14][1][2],kernal_cal[14][1][3],
                             kernal_cal[14][2][0],kernal_cal[14][2][1],kernal_cal[14][2][2],kernal_cal[14][2][3],
                             kernal_cal[14][3][0],kernal_cal[14][3][1],kernal_cal[14][3][2],kernal_cal[14][3][3]
                        };
DW_minmax #(10,16) Max_add14( .a(check_kernal[14]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[14]), .index(ind_k[14]) );

assign kernal_dil_u[14] = (op_reg==1)  ? (kernal_dil[14]>'d255)? 'd255 : kernal_dil[14][7:0]
                                            : (kernal_dil[14][8])? 'd0 : kernal_dil[14][7:0];

genvar m15;
generate
    for (m15 = 0; m15 < 4; m15 = m15 + 1) begin:m15_loop
        assign kernal[15][m15][0] = linebuffer[13-(4*m15)][120 +:8];
        assign kernal[15][m15][1] = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m15)][0:7];
        assign kernal[15][m15][2] = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m15)][8:15];
        assign kernal[15][m15][3] = (line_cnt=='d3) ? 'd0 : linebuffer[12-(4*m15)][16:23];

        assign kernal_caladd[15][m15][0] = kernal[15][m15][0] + se_s[m15][0];
        assign kernal_caladd[15][m15][1] = kernal[15][m15][1] + se_s[m15][1];
        assign kernal_caladd[15][m15][2] = kernal[15][m15][2] + se_s[m15][2];
        assign kernal_caladd[15][m15][3] = kernal[15][m15][3] + se_s[m15][3];

        assign kernal_calsub[15][m15][0] = kernal[15][m15][0] - se[m15][0];
        assign kernal_calsub[15][m15][1] = kernal[15][m15][1] - se[m15][1];
        assign kernal_calsub[15][m15][2] = kernal[15][m15][2] - se[m15][2];
        assign kernal_calsub[15][m15][3] = kernal[15][m15][3] - se[m15][3];

        assign kernal_cal[15][m15][0] = (op_reg==1) ? kernal_caladd[15][m15][0] : kernal_calsub[15][m15][0] ;
        assign kernal_cal[15][m15][1] = (op_reg==1) ? kernal_caladd[15][m15][1] : kernal_calsub[15][m15][1] ;
        assign kernal_cal[15][m15][2] = (op_reg==1) ? kernal_caladd[15][m15][2] : kernal_calsub[15][m15][2] ;
        assign kernal_cal[15][m15][3] = (op_reg==1) ? kernal_caladd[15][m15][3] : kernal_calsub[15][m15][3] ;
    end
endgenerate

assign check_kernal[15] = {  kernal_cal[15][0][0],kernal_cal[15][0][1],kernal_cal[15][0][2],kernal_cal[15][0][3],
                             kernal_cal[15][1][0],kernal_cal[15][1][1],kernal_cal[15][1][2],kernal_cal[15][1][3],
                             kernal_cal[15][2][0],kernal_cal[15][2][1],kernal_cal[15][2][2],kernal_cal[15][2][3],
                             kernal_cal[15][3][0],kernal_cal[15][3][1],kernal_cal[15][3][2],kernal_cal[15][3][3]
                        };
DW_minmax #(10,16) Max_add15( .a(check_kernal[15]), .tc(1'b1), .min_max(min_max), .value(kernal_dil[15]), .index(ind_k[15]) );

assign kernal_dil_u[15] = (op_reg==1)  ? (kernal_dil[15]>'d255)? 'd255 : kernal_dil[15][7:0]
                                            : (kernal_dil[15][8])? 'd0 : kernal_dil[15][7:0];

assign data_dil = {  kernal_dil_u[15],kernal_dil_u[14],kernal_dil_u[13],kernal_dil_u[12],
                     kernal_dil_u[11],kernal_dil_u[10],kernal_dil_u[9], kernal_dil_u[8],
                     kernal_dil_u[7],kernal_dil_u[6],  kernal_dil_u[5], kernal_dil_u[4],
                     kernal_dil_u[3],kernal_dil_u[2],  kernal_dil_u[1], kernal_dil_u[0]
                    };

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dil_cnt <= 'd0;
    end
    else if(cs==READ_PIC && rvalid_reg)begin
        dil_cnt <= dil_cnt + 1;
    end
    else  dil_cnt<= 'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kernal_cnt <= 'd0;
    end
    else if(dil_cnt>'d13 || cs==CAL_DIL)begin
        kernal_cnt <= kernal_cnt + 1;
    end
    else  kernal_cnt <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        line_cnt <= 'd0;
    end
    else if(dil_cnt>'d13 || cs==CAL_DIL)begin
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
//                      HISTOGRAM
// ===============================================================

wire pixel [0:15][0:255] ;

genvar p;
generate
    for (p = 0; p < 256; p = p + 1) begin : loop_pixel
        assign pixel[0 ][p] =  (p >= data_dram[7:0]    ) ? 1'b1 : 1'b0;
        assign pixel[1 ][p] =  (p >= data_dram[15:8]   ) ? 1'b1 : 1'b0;
        assign pixel[2 ][p] =  (p >= data_dram[23:16]  ) ? 1'b1 : 1'b0;
        assign pixel[3 ][p] =  (p >= data_dram[31:24]  ) ? 1'b1 : 1'b0;
        assign pixel[4 ][p] =  (p >= data_dram[39:32]  ) ? 1'b1 : 1'b0;
        assign pixel[5 ][p] =  (p >= data_dram[47:40]  ) ? 1'b1 : 1'b0;
        assign pixel[6 ][p] =  (p >= data_dram[55:48]  ) ? 1'b1 : 1'b0;
        assign pixel[7 ][p] =  (p >= data_dram[63:56]  ) ? 1'b1 : 1'b0;
        assign pixel[8 ][p] =  (p >= data_dram[71:64]  ) ? 1'b1 : 1'b0;
        assign pixel[9 ][p] =  (p >= data_dram[79:72]  ) ? 1'b1 : 1'b0;
        assign pixel[10][p] =  (p >= data_dram[87:80]  ) ? 1'b1 : 1'b0;
        assign pixel[11][p] =  (p >= data_dram[95:88]  ) ? 1'b1 : 1'b0;
        assign pixel[12][p] =  (p >= data_dram[103:96] ) ? 1'b1 : 1'b0;
        assign pixel[13][p] =  (p >= data_dram[111:104]) ? 1'b1 : 1'b0;
        assign pixel[14][p] =  (p >= data_dram[119:112]) ? 1'b1 : 1'b0;
        assign pixel[15][p] =  (p >= data_dram[127:120]) ? 1'b1 : 1'b0;
    end
endgenerate

genvar q;
generate
    for (q = 0; q < 256; q = q + 1) begin : loop_cnt
        assign cdf_cnt[q] =  pixel[0 ][q] + pixel[1 ][q] + pixel[2 ][q] + pixel[3 ][q]
                            + pixel[4 ][q] + pixel[5 ][q] + pixel[6 ][q] + pixel[7 ][q]
                            + pixel[8 ][q] + pixel[9 ][q] + pixel[10][q] + pixel[11][q]
                            + pixel[12][q] + pixel[13][q] + pixel[14][q] + pixel[15][q];
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
            else if(cs==READ_PIC && rvalid_reg) begin
                cdf_add[j] <= cdf_cnt[j] + cdf_add[j] ;
            end
            else if(ns==IDLE) cdf_add[j] <= 'd0;
        end
    end
endgenerate

assign check = {data_dram[7:0], 
                data_dram[15:8],
                data_dram[23:16] ,
                data_dram[31:24] ,
                data_dram[39:32] ,
                data_dram[47:40] ,
                data_dram[55:48] ,
                data_dram[63:56] ,
                data_dram[71:64] ,
                data_dram[79:72] ,
                data_dram[87:80] ,
                data_dram[95:88] ,
                data_dram[103:96] ,
                data_dram[111:104],
                data_dram[119:112],
                data_dram[127:120]
                };

DW_minmax #(8,16) Min_u ( .a(check), .tc(1'b0), .min_max(1'b0), .value(min), .index(ind) );

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
         cdf_min <= 'd255;
    end
    else if(cs==READ_PIC && rvalid_reg)begin
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
    else if(cs==READ_PIC && rvalid_reg)begin
        if(his_cdf_cnt1==256)   his_cdf_cnt1 <= his_cdf_cnt1;
        else    his_cdf_cnt1<= his_cdf_cnt1 + 'd1;
    end
    else if(ns==IDLE) his_cdf_cnt1<= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        his_cdf_cnt2<= 'd0;
    end
    else if(his_cdf_cnt1==256)begin
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
reg [0:7] result4 ;
reg [0:7] result5 ;
reg [0:7] result6 ;
reg [0:7] result7 ;
reg [0:7] result8 ;
reg [0:7] result9 ;
reg [0:7] result10;
reg [0:7] result11;
reg [0:7] result12;
reg [0:7] result13;
reg [0:7] result14;
reg [0:7] result15;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result0  <= 'd0;
        result1  <= 'd0;
        result2  <= 'd0;
        result3  <= 'd0; 
        result4  <= 'd0;
        result5  <= 'd0;
        result6  <= 'd0;
        result7  <= 'd0;
        result8  <= 'd0;
        result9  <= 'd0;
        result10 <= 'd0;
        result11 <= 'd0;
        result12 <= 'd0;
        result13 <= 'd0;
        result14 <= 'd0;
        result15 <= 'd0;
    end
    else if(cs == CAL_HIS2) begin
        result0  <= cdf_f[date_sramout[120:127]];
        result1  <= cdf_f[date_sramout[112:119 ]];
        result2  <= cdf_f[date_sramout[104:111]];
        result3  <= cdf_f[date_sramout[96:103]];
        result4  <= cdf_f[date_sramout[88:95]];
        result5  <= cdf_f[date_sramout[80 :87]];
        result6  <= cdf_f[date_sramout[72:79]];
        result7  <= cdf_f[date_sramout[64:71]];
        result8  <= cdf_f[date_sramout[56:63]];
        result9  <= cdf_f[date_sramout[48:55 ]];
        result10 <= cdf_f[date_sramout[40 :47 ]];
        result11 <= cdf_f[date_sramout[32:39]];
        result12 <= cdf_f[date_sramout[24 :31]];
        result13 <= cdf_f[date_sramout[16:23]];
        result14 <= cdf_f[date_sramout[8:15]];
        result15 <= cdf_f[date_sramout[0:7]];
    end
end

assign date_sramin2 = {result0,result1,result2,result3,result4,result5,result6,result7,result8,result9,result10,result11,result12,result13,result14,result15};

// ===============================================================
//                      SRAM 
// ===============================================================
//SRAM Declaration

SRAM_PIC PIC(.Q(Q_PIC), .CLK(clk), .CEN(1'b0), .WEN(WEN_PIC), .A(A_PIC), .D(D_PIC), .OEN(1'b0));

SRAM_PIC PIC2(.Q(Q_PIC2), .CLK(clk), .CEN(1'b0), .WEN(WEN_PIC2), .A(A_PIC2), .D(D_PIC2), .OEN(1'b0));

//WEN_PIC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WEN_PIC <= 'd1;
    end
    else if(cs==READ_PIC && rvalid_m_inf)begin
        WEN_PIC <= 'b0;
    end
    else if(cs==CAL_HIS2 && rvalid_m_inf)begin
        WEN_PIC <= 'b1;
    end
    else WEN_PIC <= 'b1;
end

//WEN_PIC2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WEN_PIC2 <= 'd1;
    end
    else if(cs==READ_PIC && op_reg!=2'd3)
        WEN_PIC2 <= 'b0;
    else if(ns==CAL_DIL)
        WEN_PIC2 <= 'b0;
    else if(ns==CAL_HIS2)begin
        WEN_PIC2 <= 'b0;
    end
    else WEN_PIC2 <= 'b1;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_cnt <= -1;
    end
    else if(cs==READ_PIC && rvalid_m_inf)begin
        sram_cnt <= sram_cnt + 'd1;
    end
    else if(cs==CAL_HIS2)begin
        sram_cnt <= sram_cnt + 'd1;
    end
    else begin
        sram_cnt <= -1;
    end
end


//A_PIC
always @(*) begin
    case(cs)
        READ_PIC:
            A_PIC = sram_cnt;
        CAL_HIS2:
            A_PIC = sram_cnt;
        default:
            A_PIC = 0;
    endcase
end

always @(*) begin
    case(cs)
        READ_PIC:
            if(op_reg==2'b10)
                A_PIC2 = 0;
            else begin
                A_PIC2 = kernal_cnt;
            end
        CAL_DIL:
            A_PIC2 = kernal_cnt;
        CAL_HIS2:
            A_PIC2 = sram_cnt - 'd3;
        WRITE:
            A_PIC2 = (wvalid_m_inf && wready_m_inf ) ? write_cnt + 1 : write_cnt;
        default:
            A_PIC2 = 0;
    endcase
end

//D_PIC
always @(*) begin
    case(cs)
        READ_PIC:
            D_PIC = data_sram;
        default:
            D_PIC = 0;
    endcase
end

always @(*) begin
    case(cs)
        READ_PIC:
            D_PIC2 = data_dil;
        CAL_DIL:
            D_PIC2 = data_dil;
        CAL_HIS2:
            D_PIC2 = date_sramin2;
        default:
            D_PIC2 = 0;
    endcase
end



//Q_PIC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        date_sramout <= 0;
    end
    else begin
        case(ns)
            CAL_HIS2:
                date_sramout <= Q_PIC;
            default:
                date_sramout <= 0;
        endcase
    end
end



endmodule
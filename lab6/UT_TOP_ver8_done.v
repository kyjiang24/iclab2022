//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : UT_TOP.v
//   Module Name : UT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


//synopsys translate_off
`include "B2BCD_IP.v"
//synopsys translate_on


module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day


);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [30:0] in_time;
output reg out_valid;
output reg [3:0] out_display;
output reg [2:0] out_day;



// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
parameter IDLE      =   2'd0;
parameter INPUT     =   2'd1;
parameter CAL       =   2'd2;
//parameter OUTPUT    =   3'd6;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [1:0] ns,cs;

reg [30:0] in_time_reg;
//reg [23:0] in_time_31;
//reg [6:0] in_time_8;
//reg [9:0] in_time_mod128;
reg [14:0] in_time_day;
reg [16:0] in_time_second;

reg [2:0] alldaymod7; //6 2^3
reg [3:0] week;
wire [4:0] fouryear;
reg [10:0] alldaymod1461;
reg [1:0] modyear;
wire [10:0] year;

reg [8:0] dayofyear;
reg [3:0] month;
wire [0:11] month_12,month_12_leap;

wire [4:0] hour;
reg [11:0]minute_second;
wire [5:0]minute,second;

reg [4:0] day;

reg [5:0] cal_cnt;

//reg [4:0] binary_in5to2;
//wire [7:0] bcd_out5to2;

reg [6:0] binary_in7to3;
wire [11:0] bcd_out7to3;

wire leapyear;
wire year20_flag;


//=============================================
//             FSM                      
//=============================================

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cs <= IDLE; 
    else 
        cs <= ns;
end

always@(*) begin
    case(cs)
    IDLE    : ns = (in_valid) ? INPUT : IDLE ;
    INPUT   : ns = (in_valid) ? INPUT : CAL;
    CAL     : ns = (cal_cnt==15) ? IDLE : CAL ;
    //OUTPUT    : ns = IDLE;
    default : ns = IDLE;
    endcase
end

//================================================================
// DESIGN
//================================================================

//INPUT

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  in_time_reg<=0;
    else if(in_valid)begin
        in_time_reg<=in_time;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  in_time_day<=0;
    else begin
        in_time_day<=(in_time_reg[30:7])/675;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  in_time_second<=0;
    else begin
        in_time_second <= in_time_reg - ((in_time_day<<7)*675);
    end
end


//CAL

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cal_cnt<= 'd0;
    end
    else if(ns==CAL)begin
        cal_cnt<= cal_cnt + 1;
    end
    else begin
        cal_cnt<= 'd0;
    end
end

//assign alldaymod7 = in_time_day%7 ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         alldaymod7 <= 'd0;
    end
    else begin
         alldaymod7 <= in_time_day%7;
    end
end

assign fouryear = in_time_day/1461;
/*
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         fouryear <= 'd0;
    end
    else begin
         fouryear <= in_time_day/1461;
    end
end
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         alldaymod1461 <= 'd0;
    end
    else begin
         //alldaymod1461 <= in_time_day%1461;
         alldaymod1461 <= in_time_day - fouryear*1461;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         modyear <= 'd0;
    end
    else begin
         if(alldaymod1461<365)  modyear<=0;
         else if(alldaymod1461>=365 && alldaymod1461<730)   modyear<=1;
         else if(alldaymod1461>=730 && alldaymod1461<1096)  modyear<=2;
         else modyear<=3;
    end
end

assign leapyear = (modyear==2) ? 1 : 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         dayofyear <= 'd0;
    end
    else begin
         case(modyear) 
            0: dayofyear <= alldaymod1461;
            1: dayofyear <= alldaymod1461-365;
            2: dayofyear <= alldaymod1461-730;
            3: dayofyear <= alldaymod1461-1096;
         endcase
    end
end

assign month_12[0] = (dayofyear<31) ? 1 : 0 ; //1
assign month_12[1] = (dayofyear<59) ? 1 : 0 ;//2
assign month_12[2] = (dayofyear<90) ? 1 : 0 ;//3
assign month_12[3] = (dayofyear<120) ? 1 : 0 ;//4
assign month_12[4] = (dayofyear<151) ? 1 : 0 ;//5
assign month_12[5] = (dayofyear<181) ? 1 : 0 ;//6
assign month_12[6] = (dayofyear<212) ? 1 : 0 ;//7
assign month_12[7] = (dayofyear<243) ? 1 : 0 ;//8
assign month_12[8] = (dayofyear<273) ? 1 : 0 ;//9
assign month_12[9] = (dayofyear<304) ? 1 : 0 ;//10
assign month_12[10] = (dayofyear<334) ? 1 : 0 ;//11
assign month_12[11] = 1 ;//12

assign month_12_leap[0] = (dayofyear<31) ? 1 : 0 ; //1
assign month_12_leap[1] = (dayofyear<60) ? 1 : 0 ;//2
assign month_12_leap[2] = (dayofyear<91) ? 1 : 0 ;//3
assign month_12_leap[3] = (dayofyear<121) ? 1 : 0 ;//4
assign month_12_leap[4] = (dayofyear<152) ? 1 : 0 ;//5
assign month_12_leap[5] = (dayofyear<182) ? 1 : 0 ;//6
assign month_12_leap[6] = (dayofyear<213) ? 1 : 0 ;//7
assign month_12_leap[7] = (dayofyear<244) ? 1 : 0 ;//8
assign month_12_leap[8] = (dayofyear<274) ? 1 : 0 ;//9
assign month_12_leap[9] = (dayofyear<305) ? 1 : 0 ;//10
assign month_12_leap[10] = (dayofyear<335) ? 1 : 0 ;//11
assign month_12_leap[11] = 1 ;//12

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         month <= 'd0;
    end
    else if(leapyear)begin
         case(month_12_leap)
            12'b1111_1111_1111 : month <= 'd1;
            12'b0111_1111_1111 : month <= 'd2;
            12'b0011_1111_1111 : month <= 'd3;
            12'b0001_1111_1111 : month <= 'd4;
            12'b0000_1111_1111 : month <= 'd5;
            12'b0000_0111_1111 : month <= 'd6;
            12'b0000_0011_1111 : month <= 'd7;
            12'b0000_0001_1111 : month <= 'd8;
            12'b0000_0000_1111 : month <= 'd9;
            12'b0000_0000_0111 : month <= 'd10;
            12'b0000_0000_0011 : month <= 'd11;
            12'b0000_0000_0001 : month <= 'd12;
         endcase
    end
    else begin
        case(month_12)
            12'b1111_1111_1111 : month <= 'd1 ;
            12'b0111_1111_1111 : month <= 'd2 ;
            12'b0011_1111_1111 : month <= 'd3 ;
            12'b0001_1111_1111 : month <= 'd4 ;
            12'b0000_1111_1111 : month <= 'd5 ;
            12'b0000_0111_1111 : month <= 'd6 ;
            12'b0000_0011_1111 : month <= 'd7 ;
            12'b0000_0001_1111 : month <= 'd8 ;
            12'b0000_0000_1111 : month <= 'd9 ;
            12'b0000_0000_0111 : month <= 'd10;
            12'b0000_0000_0011 : month <= 'd11;
            12'b0000_0000_0001 : month <= 'd12;
         endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         day <= 'd0;
    end
    else if(leapyear)begin
         case(month)
            'd1  : day <= dayofyear + 1 ;
            'd2  : day <= dayofyear - 30 ;
            'd3  : day <= dayofyear - 59 ;
            'd4  : day <= dayofyear - 90 ;
            'd5  : day <= dayofyear - 120;
            'd6  : day <= dayofyear - 151;
            'd7  : day <= dayofyear - 181;
            'd8  : day <= dayofyear - 212;
            'd9  : day <= dayofyear - 243;
            'd10 : day <= dayofyear - 273;
            'd11 : day <= dayofyear - 304;
            'd12 : day <= dayofyear - 334;
         endcase
    end
    else begin
        case(month)
            'd1  : day <= dayofyear + 1 ;
            'd2  : day <= dayofyear - 30;
            'd3  : day <= dayofyear - 58 ;
            'd4  : day <= dayofyear - 89 ;
            'd5  : day <= dayofyear - 119;
            'd6  : day <= dayofyear - 150;
            'd7  : day <= dayofyear - 180;
            'd8  : day <= dayofyear - 211;
            'd9  : day <= dayofyear - 242;
            'd10 : day <= dayofyear - 272;
            'd11 : day <= dayofyear - 303;
            'd12 : day <= dayofyear - 333;
         endcase
    end
end

assign year = 1970 + (fouryear<<2) + modyear;

assign year20_flag =  in_time_day>10956 ? 1 : 0 ;

assign hour = in_time_second[16:4] / 225;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         minute_second <= 'd0;
    end
    else begin
         minute_second <= in_time_second - hour*3600;
    end
end

assign minute = minute_second / 60;


assign second = minute_second % 60;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         out_day <= 'd0;
    end
    else begin
         case(alldaymod7)
            0: out_day <= 4;
            1: out_day <= 5;
            2: out_day <= 6;
            3: out_day <= 0;
            4: out_day <= 1;
            5: out_day <= 2;
            6: out_day <= 3;
         endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
         binary_in7to3 <= 'd0;
    end
    else begin
         case(cal_cnt)
            3 : binary_in7to3 <= year%100;
            5 : binary_in7to3 <= month;
            7 : binary_in7to3 <= day;
            9 : binary_in7to3 <= hour;
            11: binary_in7to3 <= minute;
            13: binary_in7to3 <= second;
         endcase
    end
end

B2BCD_IP #(.WIDTH(7),.DIGIT(3)) B2BCD_IP7to3(.Binary_code(binary_in7to3),.BCD_code(bcd_out7to3));

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)out_valid<=0;
    else if(cal_cnt>1)begin
        out_valid<=1;
    end
    else begin
        out_valid <= 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)out_display<=0;
    else begin
        case(cal_cnt)
              2 : out_display<= (year20_flag)? 2 : 1;
              3 : out_display<= (year20_flag)? 0 : 9;
              4 : out_display<= bcd_out7to3[7:4];
              5 : out_display<= bcd_out7to3[3:0];
              6 : out_display<= bcd_out7to3[7:4];
              7 : out_display<= bcd_out7to3[3:0];
              8 : out_display<= bcd_out7to3[7:4];
              9 : out_display<= bcd_out7to3[3:0];
             10 : out_display<= bcd_out7to3[7:4];
             11 : out_display<= bcd_out7to3[3:0];
             12 : out_display<= bcd_out7to3[7:4];
             13 : out_display<= bcd_out7to3[3:0];
             14 : out_display<= bcd_out7to3[7:4];
             15 : out_display<= bcd_out7to3[3:0];
             16 : out_display<= bcd_out7to3[7:4];
             17 : out_display<= bcd_out7to3[3:0];
            default : out_display<=0;
        endcase
    end
end
/*
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) out_day<=0;
    else begin
        out_day<=week;
    end
end
*/
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

endmodule
// synopsys translate_off 
`ifdef RTL
`include "GATED_OR.v"
`else
`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SP(
    // Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    in_data,
    in_mode,
    // Output signals
    out_valid,
    out_data
);

// INPUT AND OUTPUT DECLARATION  
input       clk;
input       rst_n;
input       in_valid;
input       cg_en;
input [8:0] in_data;
input [2:0] in_mode;

output reg        out_valid;
output reg signed[9:0] out_data;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
parameter IDLE      =   3'd0;
parameter INPUT     =   3'd1;
//parameter GRAY      =   3'd2;
parameter MID       =   3'd3;
parameter SMA       =   3'd4;
parameter CHO       =   3'd5;
parameter OUTPUT    =   3'd6;

integer i;

//================================================================
// Wire & Reg Declaration
//================================================================
reg [2:0] ns,cs;

reg [2:0] mode;
wire [8:0] data;
wire [8:0] data_gray;
reg signed [9:0] data_gray_r[0:8];
reg signed [9:0] data_sma_r[0:8];

reg signed[9:0] swap_data_in [0:8];
reg [3:0]in_cnt;
reg [1:0]out_cnt;

reg signed [9:0] min_data,mid_point_r;
wire signed [9:0] mid_point;
wire signed [9:0] min,mid,max;

wire signed [9:0] data_mid[0:8];
reg signed [9:0] data_mid_r[0:8];
wire signed [9:0] data_sma[0:8];

reg signed [9:0] sma_data_in[0:8];

reg  clk_sleep_mid;
wire clk_g_mid;

//CG_mid
GATED_OR GATED_mid(
    .CLOCK(clk),
    .SLEEP_CTRL(clk_sleep_mid),
    .RST_N(rst_n),
    .CLOCK_GATED(clk_g_mid)
);

always@(*)begin
    if(!rst_n)
        clk_sleep_mid=0;
    else begin
        case(cg_en)
            1'd1:begin
                case(cs)
//                    GRAY    :clk_sleep_mid=0;
                    MID     :clk_sleep_mid=0;
                    SMA     :clk_sleep_mid=0;
                    CHO     :clk_sleep_mid=0;
                    default :clk_sleep_mid=1;
                endcase
            end
            default:clk_sleep_mid=0;
        endcase
    end
end
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
    INPUT   : ns = (in_valid) ? INPUT : mode[1] ? MID : mode[2] ? SMA : CHO;
    MID     : ns = mode[2] ? SMA : CHO ;
    SMA     : ns = CHO ;
    CHO     : ns = OUTPUT;
    OUTPUT  : ns = (out_cnt==3) ? IDLE : OUTPUT;
    default : ns = IDLE;
    endcase
end

//================================================================
// DESIGN
//================================================================

//INPUT

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  mode<=0;
    else if(in_valid && in_cnt==0)begin
        mode<=in_mode;
    end
end

/*
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  begin
        for (i = 0; i < 9; i = i + 1)
            in_data_r[i] <=0;
    end
    else if(in_valid)begin
        in_data_r[in_cnt] <= in_data;
    end
end
*/

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  in_cnt<=0;
    else if(in_valid)begin
        in_cnt <= in_cnt + 'd1;
    end
    else in_cnt <= 'd0;
end

//GRAY
assign data[8] = in_data[8];
assign data[7] = in_data[7];
assign data[6] = data[7] ^ in_data[6] ;
assign data[5] = data[6] ^ in_data[5] ;
assign data[4] = data[5] ^ in_data[4] ;
assign data[3] = data[4] ^ in_data[3] ;
assign data[2] = data[3] ^ in_data[2] ;
assign data[1] = data[2] ^ in_data[1] ;
assign data[0] = data[1] ^ in_data[0] ;

assign data_gray = (in_cnt==0) ? (in_mode[0]==0)? in_data : (data[8]) ? {1'b1, ((~data[7:0]) + 'd1) } : data 
                                : (mode[0]==0) ? in_data : (data[8]) ? {1'b1, ((~data[7:0]) + 'd1) } : data ;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  
        for (i = 0; i < 9; i = i + 1)
            data_gray_r[i] <=0;
    else if(in_valid)begin
        data_gray_r[in_cnt] <=  $signed(data_gray);
    end
end

/*
generate
    genvar j;
    for (j = 0; j < 9; j = j + 1) begin:identifier
        assign data[j][8] = in_data_r[j][8];
        assign data[j][7] = in_data_r[j][7];
        assign data[j][6] = data[j][7] ^ in_data_r[j][6] ;
        assign data[j][5] = data[j][6] ^ in_data_r[j][5] ;
        assign data[j][4] = data[j][5] ^ in_data_r[j][4] ;
        assign data[j][3] = data[j][4] ^ in_data_r[j][3] ;
        assign data[j][2] = data[j][3] ^ in_data_r[j][2] ;
        assign data[j][1] = data[j][2] ^ in_data_r[j][1] ;
        assign data[j][0] = data[j][1] ^ in_data_r[j][0] ;

        assign data_gray[j] = (mode[0]==0) ? in_data_r[j] :
                                (data[j][8]) ? {1'b1, ((~data[j][7:0])+ 'd1) } : data[j] ;
    end
endgenerate
*/



always @(*) begin
    if (cs==MID) begin
        for (i = 0; i < 9; i = i + 1)
            swap_data_in[i] = data_gray_r[i];
    end
    else if(cs==CHO)begin
        if(mode[2])
            for (i = 0; i < 9; i = i + 1)
                swap_data_in[i] = data_sma_r[i];
        else if(mode[1])
            for (i = 0; i < 9; i = i + 1)
                swap_data_in[i] = data_mid_r[i];
        else
            for (i = 0; i < 9; i = i + 1)
                swap_data_in[i] = data_gray_r[i];
    end
    else begin
        for (i = 0; i < 9; i = i + 1)
            swap_data_in[i] = 'd0;
    end
end


//MID


MAX_MID_MIN mmm_1(.in1(swap_data_in[0]),.in2(swap_data_in[1]),.in3(swap_data_in[2]),.in4(swap_data_in[3]),.in5(swap_data_in[4]),.in6(swap_data_in[5]),.in7(swap_data_in[6]),.in8(swap_data_in[7]),.in9(swap_data_in[8]),.max(max),.mid(mid_point),.min(min));

always @(posedge clk_g_mid or negedge rst_n) begin
    if (!rst_n) begin
        min_data <= 'd0;
    end
    else if(cs==MID || cs==CHO)begin
        min_data <= min;
    end
end

wire signed [10:0] temp_add;
assign temp_add = max + min;

assign mid = (temp_add[10] && temp_add[0]) ? (temp_add>>>1)+ 'd1 : (temp_add>>>1);

always @(posedge clk_g_mid or negedge rst_n) begin
    if (!rst_n) begin
        mid_point_r <= 'd0;
    end
    else if(cs==CHO)begin
        mid_point_r <= mid_point;
    end
end

wire signed [9:0] temp_sub;
wire signed [9:0] half;
assign temp_sub = max - min;

assign half = (temp_sub[9] && temp_sub[0]) ? (temp_sub>>>1) + 'd1 :(temp_sub>>>1) ;

genvar k;
generate
    for (k = 0; k < 9; k = k + 1)begin:loop_mid
        assign  data_mid[k] = (data_gray_r[k]>mid) ? data_gray_r[k]- half : (data_gray_r[k]<mid) ? data_gray_r[k] + half : data_gray_r[k];
    end
endgenerate

always@(posedge clk_g_mid or negedge rst_n)begin
    if(!rst_n)  
        for (i = 0; i < 9; i = i + 1)
            data_mid_r[i] <=0;
    else if(cs==MID)begin
        for (i = 0; i < 9; i = i + 1)
            data_mid_r[i] <= data_mid[i];
    end
end

always @(*) begin
    if (cs==SMA) begin
        if(mode[1]) begin
            for (i = 0; i < 9; i = i + 1)
                sma_data_in[i] = data_mid_r[i];
        end
        else begin
            for (i = 0; i < 9; i = i + 1)
                sma_data_in[i] = data_gray_r[i];
        end
    end
    else begin
        for (i = 0; i < 9; i = i + 1)
            sma_data_in[i] = 'd0;
    end
end

//SMA

wire signed [10:0] temp_sma [0:8];
assign temp_sma[0] = sma_data_in[8] + sma_data_in[0] + sma_data_in[1];
//assign data_sma[0] = temp_sma [0][10] ? (((temp_sma[0])/3) + 'd1) : (temp_sma [0])/3;
assign data_sma[0] =  temp_sma [0]/3;

assign temp_sma[1] = sma_data_in[0] + sma_data_in[1] + sma_data_in[2];
assign data_sma[1] = temp_sma[1]/3;

assign temp_sma[2] = sma_data_in[1] + sma_data_in[2] + sma_data_in[3];
assign data_sma[2] = temp_sma [2]/3;

assign temp_sma[3] = sma_data_in[2] + sma_data_in[3] + sma_data_in[4];
assign data_sma[3] = temp_sma[3]/3;

assign temp_sma[4] = sma_data_in[3] + sma_data_in[4] + sma_data_in[5];
assign data_sma[4] = temp_sma[4]/3;

assign temp_sma[5] = sma_data_in[4] + sma_data_in[5] + sma_data_in[6];
assign data_sma[5] = temp_sma[5]/3;

assign temp_sma[6] = sma_data_in[5] + sma_data_in[6] + sma_data_in[7];
assign data_sma[6] = temp_sma[6]/3;

assign temp_sma[7] = sma_data_in[6] + sma_data_in[7] + sma_data_in[8];
assign data_sma[7] = temp_sma[7]/3;

assign temp_sma[8] = sma_data_in[7] + sma_data_in[8] + sma_data_in[0];
assign data_sma[8] = temp_sma[8]/3;


always@(posedge clk_g_mid or negedge rst_n)begin
    if(!rst_n)  
        for (i = 0; i < 9; i = i + 1)
            data_sma_r[i] <=0;
    else if(cs==SMA)begin
        for (i = 0; i < 9; i = i + 1)
            data_sma_r[i] <= data_sma[i];
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

//output

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        out_cnt<=0;
    else if(ns==OUTPUT)begin
       out_cnt <= out_cnt + 'd1;
    end
    else begin
        out_cnt <= 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        out_valid<=0;
    else if(ns==OUTPUT)begin
       out_valid <= 'd1;
    end
    else begin
        out_valid <= 0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) 
        out_data<=0;
    else if(ns==OUTPUT)begin
        case(out_cnt)
            0: out_data <= max;
            1: out_data <= mid_point_r;
            2: out_data <= min_data;
        endcase
    end
    else begin
        out_data <= 0;
    end
end

endmodule

//MAX_MID_MIN mmm_1(.in1(),.in2(),.in3(),.in4(),.in5(),.in6(),.in7(),.in8(),.in9(),.max(),.mid(),.min());

module MAX_MID_MIN(in1,in2,in3,in4,in5,in6,in7,in8,in9,max,mid,min);

input signed [9:0] in1,in2,in3,in4,in5,in6,in7,in8,in9;
output signed [9:0] max,mid,min;

wire signed [9:0] max_1,mid_1,min_1;
wire signed [9:0] max_2,mid_2,min_2;
wire signed [9:0] max_3,mid_3,min_3;
wire signed [9:0] max_4,min_4;
wire signed [9:0] mid_5;
wire signed [9:0] max_6,min_6;
wire signed [9:0] mid_7;

CS CS_1(.inA(in1),.inB(in2),.inC(in3),.max(max_1),.mid(mid_1),.min(min_1));
CS CS_2(.inA(in4),.inB(in5),.inC(in6),.max(max_2),.mid(mid_2),.min(min_2));
CS CS_3(.inA(in7),.inB(in8),.inC(in9),.max(max_3),.mid(mid_3),.min(min_3));
CS CS_4(.inA(max_1),.inB(max_2),.inC(max_3),.max(max_4),.mid(),.min(min_4));
CS CS_5(.inA(mid_1),.inB(mid_2),.inC(mid_3),.max(),.mid(mid_5),.min());
CS CS_6(.inA(min_1),.inB(min_2),.inC(min_3),.max(max_6),.mid(),.min(min_6));
CS CS_7(.inA(min_4),.inB(mid_5),.inC(max_6),.max(),.mid(mid_7),.min());

assign max = max_4;
assign mid = mid_7;
assign min = min_6;

endmodule



module CS(inA,inB,inC,max,mid,min);
input signed [9:0] inA,inB,inC;
output reg signed [9:0] max,mid,min;

wire com1,com2,com3;
wire [2:0] s_in;

assign com1 = (inA>inB) ? 1'b1 : 1'b0 ;
assign com2 = (inA>inC) ? 1'b1 : 1'b0 ;
assign com3 = (inB>inC) ? 1'b1 : 1'b0 ;

assign s_in = {com1,com2,com3};

always @(*) begin
    case(s_in)
        3'd7,3'd6:begin
            max = inA ;
        end
        3'd3,3'b1:begin
            max = inB ;
        end
        3'd4,3'd0:begin
            max = inC ;
        end
        default: begin
            max = 'd0 ;
        end
    endcase
end

always @(*) begin
    case(s_in)
        3'd4,3'd3:begin
            mid = inA ;
        end
        3'd7,3'd0:begin
            mid = inB ;
        end
        3'd6,3'd1:begin
            mid = inC ;
        end
        default: begin
            mid = 'd0 ;
        end
    endcase
end

always @(*) begin
    case(s_in)
        3'd1,3'd0:begin
            min = inA ;
        end
        3'd6,3'd4:begin
            min = inB ;
        end
        3'd7,3'd3:begin
            min = inC ;
        end
        default: begin
            min = 'd0 ;
        end
    endcase
end

endmodule
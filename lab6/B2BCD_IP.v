//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : B2BCD_IP.v
//   Module Name : B2BCD_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module B2BCD_IP #(parameter WIDTH = 19, parameter DIGIT = 6) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Soft IP DESIGN
// ===============================================================
wire [DIGIT*4+1:0] line[WIDTH-4:0];
wire [DIGIT*4-1:0] indata;
//wire [DIGIT*4-1:0] P ;
assign indata = Binary_code;
genvar i,j;
generate 
for(i=0;i<=WIDTH-4;i=i+1) begin: loop_depth    
    if(i==0) begin
        assign line[0] = (indata[WIDTH:WIDTH-3]>4'd4) ? {2'b00,indata[DIGIT*4-1:WIDTH+1],indata[WIDTH:WIDTH-3]+4'd3,indata[WIDTH-4:0]} : indata ;
    end
    else begin
        for(j=0;j<=i/3;j=j+1) begin: loop_width
            assign line[i][(WIDTH-i+(i/3)*4 - 4*j)-:4] = (line[i-1][(WIDTH-i+(i/3)*4 - 4*j)-:4] > 4'd4) ? line[i-1][(WIDTH-i+(i/3)*4 - 4*j)-:4] +4'd3 : line[i-1][(WIDTH-i+(i/3)*4 - 4*j)-:4];
        end
    assign line[i][WIDTH-i-4:0] = line[i-1][WIDTH-i-4:0] ;
    assign line[i][DIGIT*4+1:WIDTH-i+(i/3)*4+1] = line[i-1][DIGIT*4+1:WIDTH-i+(i/3)*4+1] ;
    end
end
endgenerate

assign BCD_code = line[WIDTH-4][DIGIT*4-1:0] ;

endmodule
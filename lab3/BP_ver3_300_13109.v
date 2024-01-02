module BP(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);

input             clk, rst_n;
input             in_valid;
input       [2:0] guy;
input       [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg        out_valid;
output reg  [1:0] out;


parameter IDLE    = 2'd0;
parameter INPUT_0 = 2'd1;
parameter INPUT   = 2'd2;
parameter OUT     = 2'd3;

reg [1:0] ns,cs;
reg [7:0] left;
reg [7:0] right;
reg [62:0] ans_left ;
reg [62:0] ans_right ;
reg [2:0] index_x;
reg [2:0] exit_x;
reg [1:0] obstacle;
reg [5:0] ans_cnt;

wire wall;
wire [1:0]direction;
wire [2:0]diff_x;

//==============================================//
//             Current State Block              //
//==============================================//

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cs <= IDLE; /* initial state */
    else 
        cs <= ns;
end

//==============================================//
//              Next State Block                //
//==============================================//

always@(*) begin
    case(cs)
    IDLE :  ns = (in_valid) ? INPUT_0 : IDLE ;
    INPUT_0: ns = INPUT;
    INPUT : ns = (in_valid) ? INPUT : OUT;
    OUT : ns = (ans_cnt==6'd63)? IDLE : OUT;
    default : ns = IDLE;
    endcase
end

assign wall = (ns==INPUT && in0)? 1'b1 : 1'b0 ;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      index_x <= 'd0;
    else if(ns == INPUT_0)
      index_x <= guy;
    else if(wall) begin
      index_x <= exit_x;
    end
end

always@(*) begin
    if(ns == INPUT_0)
      exit_x = guy;
    else if(wall)begin
      if(in0!=2'd3)  exit_x = 3'd0;
      else if(in1!=2'd3) exit_x =3'd1;
      else if(in2!=2'd3) exit_x =3'd2;
      else if(in3!=2'd3) exit_x =3'd3;
      else if(in4!=2'd3) exit_x =3'd4;
      else if(in5!=2'd3) exit_x =3'd5;
      else if(in6!=2'd3) exit_x =3'd6;
      else exit_x =3'd7;
    end
    else exit_x = 3'd0;
end

always@(*) begin
    if(wall)begin
      if(in0!=2'd3)  obstacle = in0;
      else if(in1!=2'd3) obstacle = in1;
      else if(in2!=2'd3) obstacle = in2;
      else if(in3!=2'd3) obstacle = in3;
      else if(in4!=2'd3) obstacle = in4;
      else if(in5!=2'd3) obstacle = in5;
      else if(in6!=2'd3) obstacle = in6;
      else obstacle = in7;
    end
    else obstacle = 2'd0;
end

assign direction = (exit_x>index_x) ? 2'd1 : (exit_x < index_x) ? 2'd2 : 2'd0; //left:2,right:1,straight:0
assign diff_x = (direction==2'd1)? exit_x - index_x : index_x - exit_x;

always @(*) begin
  if(wall) begin
    if(obstacle==3'd1) begin //need to jump
      if(direction==2'd1) begin //go right
        case(diff_x)
          3'd1 : right = 8'b0000_0011;
          3'd2 : right = 8'b0000_0111;
          3'd3 : right = 8'b0000_1111;
          3'd4 : right = 8'b0001_1111;
          3'd5 : right = 8'b0011_1111;
          3'd6 : right = 8'b0111_1111;                   
          3'd7 : right = 8'b1111_1111;
          default : right = 8'b0000_0001;
        endcase
      end
      else begin //go left or straight
        right = 8'b0000_0001;
      end
    end
    else begin //don't need to jump
      if(direction==2'd1) begin //go right
        case(diff_x)
          3'd1 : right = 8'b0000_0001;
          3'd2 : right = 8'b0000_0011;
          3'd3 : right = 8'b0000_0111;
          3'd4 : right = 8'b0000_1111;
          3'd5 : right = 8'b0001_1111;
          3'd6 : right = 8'b0011_1111;                
          3'd7 : right = 8'b0111_1111;
          default : right = 8'b0000_0000;
        endcase
      end
      else begin //go left or straight
        right = 8'b0000_0000;
      end
    end
  end
  else begin
    right = 8'b0000_0000;
  end
end

always @(*) begin
  if(wall) begin
    if(obstacle==3'd1) begin //need to jump
      if(direction==2'd2) begin //go left
        case(diff_x)
          3'd1 : left = 8'b0000_0011;
          3'd2 : left = 8'b0000_0111;
          3'd3 : left = 8'b0000_1111;
          3'd4 : left = 8'b0001_1111;
          3'd5 : left = 8'b0011_1111;
          3'd6 : left = 8'b0111_1111;                  
          3'd7 : left = 8'b1111_1111;
          default : left = 8'b0000_0001;
        endcase
      end
      else begin //go right or straight
        left = 8'b0000_0001;
      end
    end
    else begin //don't need to jump
      if(direction==2'd2) begin //go left
        case(diff_x)
          3'd1 : left = 8'b0000_0001;
          3'd2 : left = 8'b0000_0011;
          3'd3 : left = 8'b0000_0111;
          3'd4 : left = 8'b0000_1111;
          3'd5 : left = 8'b0001_1111;
          3'd6 : left = 8'b0011_1111;                  
          3'd7 : left = 8'b0111_1111;
          default : left = 8'b0000_0000;
        endcase
      end
      else begin //go right or straight
        left = 8'b0000_0000;
      end
    end
  end
  else left = 8'b0000_0000;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin    
    ans_right <= 63'd0;
  end
  else if(ns == IDLE) begin  
    ans_right <= 63'd0;
  end
  else if(wall)begin
    ans_right <=  (ans_right<<1) | {{55{1'b0}},right} ;
  end
  else 
    ans_right <= ans_right<<1 ;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    ans_left <= 63'd0;
  end
  else if(ns == IDLE) begin
    ans_left <= 63'd0;
  end
  else if(wall)begin
    ans_left <=  (ans_left<<1) | {{55{1'b0}},left};
  end
  else ans_left <= (ans_left << 1);
end

//out_valid
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)  out_valid <= 1'd0;
    else begin
        out_valid <= (ns==OUT) ;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)  out <= 2'd0;
    else if(ns == OUT) begin
      out <= {ans_left[62],ans_right[62]};
    end
    else begin
      out <= 2'd0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      ans_cnt <= 6'd0;
    else if(ns == OUT) begin
      ans_cnt <= ans_cnt + 6'd1;
    end
    else begin
      ans_cnt <= 6'd0;
    end
end
    
endmodule

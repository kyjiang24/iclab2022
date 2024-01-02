module HD(
	code_word1,
	code_word2,
	out_n
);
input  [6:0]code_word1, code_word2;
output signed[5:0] out_n;

wire circle1_w1,circle2_w1,circle3_w1;
wire circle1_w2,circle2_w2,circle3_w2;
reg signed[3:0] c1,c2;
reg signed[5:0] in1,in2;
reg [1:0] opt;

assign circle1_w1 = code_word1[6]^code_word1[3]^code_word1[2]^code_word1[1];
assign circle2_w1 = code_word1[5]^code_word1[3]^code_word1[2]^code_word1[0];
assign circle3_w1 = code_word1[4]^code_word1[3]^code_word1[1]^code_word1[0];

assign circle1_w2 = code_word2[6]^code_word2[3]^code_word2[2]^code_word2[1];
assign circle2_w2 = code_word2[5]^code_word2[3]^code_word2[2]^code_word2[0];
assign circle3_w2 = code_word2[4]^code_word2[3]^code_word2[1]^code_word2[0];

always@(*) begin
	case({circle1_w1, circle2_w1, circle3_w1})	
	3'b001:begin
		opt[1] = code_word1[4];
		c1 = {code_word1[3],code_word1[2],code_word1[1],code_word1[0]};
	end
	3'b010:begin
		opt[1] = code_word1[5];
		c1 = {code_word1[3],code_word1[2],code_word1[1],code_word1[0]};
	end
	3'b100:begin
		opt[1] = code_word1[6];
		c1 = {code_word1[3],code_word1[2],code_word1[1],code_word1[0]};
	end
	3'b011:begin
		opt[1] = code_word1[0];
		c1 = {code_word1[3],code_word1[2],code_word1[1],~code_word1[0]};
	end
	3'b101:begin
		opt[1] = code_word1[1];
		c1 = {code_word1[3],code_word1[2],~code_word1[1],code_word1[0]};
	end
	3'b110:begin
		opt[1] = code_word1[2];
		c1 = {code_word1[3],~code_word1[2],code_word1[1],code_word1[0]};
	end
	default:begin//3'd111
		opt[1] = code_word1[3];
		c1 = {~code_word1[3],code_word1[2],code_word1[1],code_word1[0]};
	end 
	endcase
end

always@(*) begin
	case({circle1_w2, circle2_w2, circle3_w2})	
	3'b001:begin
		opt[0] = code_word2[4];
		c2 = {code_word2[3],code_word2[2],code_word2[1],code_word2[0]};
	end
	3'b010:begin
		opt[0] = code_word2[5];
		c2 = {code_word2[3],code_word2[2],code_word2[1],code_word2[0]};
	end
	3'b100:begin
		opt[0] = code_word2[6];
		c2 = {code_word2[3],code_word2[2],code_word2[1],code_word2[0]};
	end
	3'b011:begin
		opt[0] = code_word2[0];
		c2 = {code_word2[3],code_word2[2],code_word2[1],~code_word2[0]};
	end
	3'b101:begin
		opt[0] = code_word2[1];
		c2 = {code_word2[3],code_word2[2],~code_word2[1],code_word2[0]};
	end
	3'b110:begin
		opt[0] = code_word2[2];
		c2 = {code_word2[3],~code_word2[2],code_word2[1],code_word2[0]};
	end
	default:begin//3'd111
		opt[0] = code_word2[3];
		c2 = {~code_word2[3],code_word2[2],code_word2[1],code_word2[0]};
	end 
	endcase
end

always@(*) begin
	case(opt)
	2'b00 :begin
			in1 = c1<<<1;
			in2 = c2;
		end
	2'b01 :begin
			in1 = c1<<<1;
			in2 = -c2;
		end
	2'b10 :begin
			in1 = c1;
			in2 = -c2 <<<1;
		end
	default:begin
			in1 = c1;
			in2 = c2<<<1;
		end 
	endcase
end
adder a1(.out(out_n),.in1(in1),.in2(in2));

endmodule

module adder(out,in1,in2);
input signed [5:0] in1,in2;
output signed [5:0] out;

assign out = in1 + in2 ;

endmodule
module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================

//================================================================
// state 
//================================================================

//================================================================
//   FSM
//================================================================

//C_out_valid
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_out_valid <= 'd0;
    else if(inf.R_VALID || inf.B_VALID)
    	inf.C_out_valid <= 'd1;
    else
		inf.C_out_valid <= 'd0;
end

//C_data_r
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)
		inf.C_data_r <= 'd0;
	else if(inf.R_VALID)
		inf.C_data_r <= inf.R_DATA;
end

//AR_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.AR_VALID <= 'd0;
    else if(inf.AR_READY)
    	inf.AR_VALID <= 'd0;
    else if(inf.C_in_valid && inf.C_r_wb)
    	inf.AR_VALID <= 'd1;
end

//AR_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.AR_ADDR <= 'd0; 
    else if(inf.C_in_valid && inf.C_r_wb)
    	inf.AR_ADDR <= {6'b1000_00,inf.C_addr,3'b000}; //[16:0]
end

//R_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.R_READY <= 'd0;
	else if(inf.R_VALID)
		inf.R_READY <= 'd0; 
    else if(inf.AR_VALID)
    	inf.R_READY <= 'd1;
end

//AW_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.AW_VALID <= 'd0;
    else if(inf.AW_READY)
    	inf.AW_VALID <= 'd0;
	else if(inf.C_in_valid && inf.C_r_wb==0)
		inf.AW_VALID <= 'd1;
end

//AW_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.AW_ADDR <= 'd0; 
    else if(inf.C_in_valid && inf.C_r_wb==0)
    	inf.AW_ADDR <= {6'b1000_00,inf.C_addr,3'b000}; //[16:0]
end

//W_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.W_VALID <= 'd0;
    else if(inf.W_READY)
    	inf.W_VALID <= 'd0;
    else if(inf.AW_READY)
    	inf.W_VALID <= 'd1;
end

//W_DATA
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.W_DATA <= 'd0;
	else if(inf.AW_VALID)
		inf.W_DATA <= inf.C_data_w;
end

//B_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.B_READY <= 'd0;
    else if(inf.B_VALID)
    	inf.B_READY <= 'd0;
    else if(inf.AW_READY)
    	inf.B_READY <= 'd1;
end

endmodule
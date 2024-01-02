module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group

covergroup spec1 @(posedge clk iff inf.id_valid);
	coverpoint inf.D.d_id[0] {
    	bins deli_id[] = {[0:255]};
	}

	option.at_least = 1;
	option.auto_bin_max = 256;
endgroup

spec1 cov_1 = new();

covergroup spec2 @(posedge clk iff inf.act_valid);
	coverpoint inf.D.d_act[0]{
		bins acttoact[] = (Take, Order, Deliver, Cancel => Take, Order, Deliver, Cancel);
	}

	option.at_least = 10;
endgroup

spec2 cov_2 = new();

covergroup spec3 @(negedge clk iff inf.out_valid);
	coverpoint inf.complete{
		bins complete_0 = {0};
		bins complete_1 = {1};
	}

	option.at_least = 200;
endgroup

spec3 cov_3 = new();

covergroup spec4 @(negedge clk iff inf.out_valid);
	coverpoint inf.err_msg{
		bins err[] = {No_Food, D_man_busy, No_customers, Res_busy, Wrong_cancel, Wrong_res_ID, Wrong_food_ID};
	}

	option.at_least = 20;
endgroup

spec4 cov_4 = new();



//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;
//write other assertions
//========================================================================================================================================================
// Assertion 1 ( All outputs signals (including FD.sv and bridge.sv) should be zero after reset.)
//========================================================================================================================================================

assert_1 : assert property ( @(posedge rst_reg) (rst_reg===0) |-> ((inf.out_valid===0) && (inf.err_msg===0) && (inf.complete===0) && (inf.out_info===0) && 
													(inf.C_addr===0) && (inf.C_data_w===0) && (inf.C_in_valid===0) && (inf.C_r_wb===0) &&
													(inf.C_out_valid===0) && (inf.C_data_r===0) && (inf.AR_VALID===0) && (inf.AR_ADDR===0) && 
													(inf.R_READY===0) && (inf.AW_VALID===0) && (inf.AW_ADDR===0) && (inf.W_VALID===0) && (inf.W_DATA===0) && 
													(inf.B_READY===0)))
else begin
	$display("Assertion 1 is violated");
	$fatal;
end

assert_2 : assert property ( @(negedge clk) (inf.out_valid && inf.complete) |-> (inf.err_msg==='d0))
else begin
	$display("Assertion 2 is violated");
	$fatal;
end

assert_3 : assert property ( @(negedge clk) ( inf.out_valid && (!inf.complete) ) |-> (inf.out_info==='d0))
else begin
	$display("Assertion 3 is violated");
	$fatal;
end


Action action;
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)				
		action <= No_action;
    else if (inf.out_valid) 	
		action <= No_action;
	else if (inf.act_valid) begin
		//if(inf.D.d_act[0])	action <= inf.D.d_act[0];
		//else	action <= No_action;
		action <= inf.D.d_act[0];
	end
end

assert_4_1 : assert property( @(negedge clk) ( inf.act_valid) |=> ##[1:5](inf.id_valid || inf.cus_valid || inf.res_valid || inf.food_valid) )
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_2 : assert property( @(negedge clk) ( (action===Take) && inf.id_valid) |=> ##[1:5](inf.cus_valid) )
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_3 : assert property( @(negedge clk) ( (action===Order) && inf.res_valid) |=> ##[1:5](inf.food_valid) )
else begin
	$display("Assertion 4 is violated");
    $fatal; 
end

assert_4_4 : assert property( @(negedge clk) ( (action===Cancel) && inf.res_valid) |=> ##[1:5](inf.food_valid) )
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_5 : assert property( @(negedge clk) ( (action===Cancel) && inf.food_valid) |=> ##[1:5](inf.id_valid) )
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

logic [2:0] in_valids;
always_comb begin
	in_valids = inf.id_valid + inf.act_valid + inf.cus_valid + inf.res_valid + inf.food_valid;
end

assert_4_6 : assert property( @(negedge clk) in_valids |=> (in_valids===0) )
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_5_1 : assert property( @(posedge clk) (in_valids<2) )
else begin
	$display("Assertion 5 is violated");
	$fatal;
end

assert_6 : assert property( @(posedge clk) inf.out_valid |=> (!inf.out_valid) )
else begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_7_1 : assert property( @(posedge clk) inf.out_valid |=> ##[1:9]inf.act_valid )
else begin
	$display("Assertion 7 is violated");
	$fatal;
end

assert_7_2 : assert property( @(posedge clk) inf.out_valid |=> (in_valids === 0) )
else begin
	$display("Assertion 7 is violated");
	$fatal;
end

assert_7_3 : assert property( @(posedge clk) inf.out_valid |-> (in_valids === 0) )
else begin
	$display("Assertion 7 is violated");
	$fatal;
end

assert_8_1 : assert property( @(posedge clk) ((action===Take) && inf.cus_valid) |-> ##[1:1200](inf.out_valid) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end

assert_8_2 : assert property( @(posedge clk) ((action===Deliver) && inf.id_valid) |-> ##[1:1200](inf.out_valid) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end

assert_8_3 : assert property( @(posedge clk) ((action===Order) && inf.food_valid) |-> ##[1:1200](inf.out_valid) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end

assert_8_4 : assert property( @(posedge clk) ((action===Cancel) && inf.id_valid) |-> ##[1:1200](inf.out_valid) )
else begin
	$display("Assertion 8 is violated");
	$fatal;
end



endmodule
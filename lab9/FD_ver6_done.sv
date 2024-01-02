module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// parameter 
//===========================================================================

//===========================================================================
// logic 
//===========================================================================
State cs, ns;
Action act_r;

Delivery_man_id 	curr_deli_id;
Restaurant_id 		curr_res_id,custom_take_res_id;

food_ID_servings	order_food_info;

D_man_Info deli_ori_info, deli_aft_info,deli_temp_info;
Ctm_Info custom_take_info;
res_info res_ori_info,res_info_take;

logic cus_valid_r,food_valid_r;
logic flag_res_take,flag_nofood,flag_deli_busy,flag_needed,flag_in,flag_cancel,flag_cout,flag_no_cus,flag_deliver,flag_order,flag_res_val,flag_food_val,flag_res_busy,flag_wro_cancel,flag_wro_res,flag_wro_food;
//===========================================================================
// FSM 
//===========================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		
		cs <= ST_IDLE ;
	else 				
		cs <= ns ;
end

always_comb begin
	case(cs)
		ST_IDLE: begin
			ns = (inf.act_valid) ? ST_ACT : ST_IDLE ;
		end
		ST_ACT 	:begin
			if(flag_needed) begin
				if(cus_valid_r)
					ns = ST_TAKE_READ;
				else if(food_valid_r)
					ns = ST_ORDER_READ;
				else
					ns = ST_ACT;
			end
			else if(flag_cout) begin
				case(act_r)
					Take 	: ns = ST_TAKE_READ;
					Deliver	: ns = ST_DELIVER;
					Order 	: ns = ST_ORDER_READ;
					Cancel 	: ns = ST_CANCEL_READ;
					default : ns = ST_IDLE;
				endcase
			end
			else 
				ns = ST_ACT;
		end
		ST_TAKE_READ 	: ns = (flag_nofood || flag_deli_busy) ? ST_OUTPUT : (flag_res_take) ? ST_TAKE_WRITE_D : ST_TAKE_READ;
		ST_TAKE_WRITE_D	: ns = (inf.C_out_valid) ? ST_TAKE_WRITE_R : ST_TAKE_WRITE_D;
		ST_TAKE_WRITE_R	: ns = (inf.C_out_valid) ? ST_OUTPUT : ST_TAKE_WRITE_R;
		ST_DELIVER		: ns = (flag_no_cus||inf.C_out_valid) ? ST_OUTPUT : ST_DELIVER;
		ST_ORDER_READ 	: ns = (flag_res_busy) ? ST_OUTPUT : (flag_order) ? ST_ORDER_WRITE : ST_ORDER_READ;
		ST_ORDER_WRITE	: ns = (inf.C_out_valid) ? ST_OUTPUT : ST_ORDER_WRITE;
		ST_CANCEL_READ 	: ns = (flag_wro_cancel || flag_wro_res || flag_wro_food) ? ST_OUTPUT :  (inf.C_out_valid) ? ST_OUTPUT : ST_CANCEL_READ;
		ST_CANCEL_WRITE : ns = (inf.C_out_valid) ? ST_OUTPUT : ST_CANCEL_WRITE;
		ST_OUTPUT	: ns = ST_IDLE;
		default:  ns = ST_IDLE;
	endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		
		cus_valid_r <= 'd0 ;
	else 				
		cus_valid_r <= inf.cus_valid ;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		
		food_valid_r <= 'd0 ;
	else 				
		food_valid_r <= inf.food_valid ;
end
//flag_in
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_in <= 'd1;
	else if(ns==ST_ACT)begin
		if(inf.id_valid || inf.res_valid)
			flag_in <= 'd0;
	end
	else
		flag_in <= 'd1;
end

//flag_needed
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_needed <= 'd0;
	else if(flag_in)begin
		if(inf.cus_valid || inf.food_valid)
			flag_needed <= 'd1;
		else if(flag_needed)
			flag_needed <= 'd0;
	end
	else
		flag_needed <= 'd0;
end

//act_r
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		act_r <= 'd0;
	else if(inf.act_valid)
		act_r <= inf.D[3:0];
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_cout <= 'd0;
	else 
		flag_cout <= inf.C_out_valid;
end

//curr_deli_id
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		curr_deli_id <= 8'd0;
	else if(inf.id_valid)
		curr_deli_id <= inf.D.d_id[0];
end

//curr_res_id
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		curr_res_id <= 'd0;
	else if(inf.res_valid)
		curr_res_id <= inf.D.d_res_id[0];
end

//flag_res_take
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_res_take <= 'd0;
	else if(cs==ST_TAKE_READ && inf.C_out_valid)begin
		flag_res_take <= 'd1;
	end
	else
		flag_res_take <= 'd0;
end
//res_info_take
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		res_info_take <= 'd0;
	else if(cs==ST_TAKE_READ && inf.C_out_valid)begin
		res_info_take <= {inf.C_data_r[7:0],inf.C_data_r[15:8],inf.C_data_r[23:16],inf.C_data_r[31:24]};
	end
	else if(flag_res_take && !flag_nofood)begin
		case(custom_take_info.food_ID)
			FOOD1 : begin
				res_info_take.limit_num_orders <= res_info_take.limit_num_orders;
				res_info_take.ser_FOOD1 <= res_info_take.ser_FOOD1 - custom_take_info.ser_food;
				res_info_take.ser_FOOD2 <= res_info_take.ser_FOOD2;
				res_info_take.ser_FOOD3 <= res_info_take.ser_FOOD3;
			end
			FOOD2 : begin
				res_info_take.limit_num_orders <= res_info_take.limit_num_orders;
				res_info_take.ser_FOOD1 <= res_info_take.ser_FOOD1;
				res_info_take.ser_FOOD2 <= res_info_take.ser_FOOD2 - custom_take_info.ser_food;
				res_info_take.ser_FOOD3 <= res_info_take.ser_FOOD3;
			end
			FOOD3 : begin
				res_info_take.limit_num_orders <= res_info_take.limit_num_orders;
				res_info_take.ser_FOOD1 <= res_info_take.ser_FOOD1;
				res_info_take.ser_FOOD2 <= res_info_take.ser_FOOD2;
				res_info_take.ser_FOOD3 <= res_info_take.ser_FOOD3 - custom_take_info.ser_food;
			end
		endcase
	end
	else if(flag_order)begin
		if(flag_res_busy) begin
			res_info_take <= res_ori_info;
		end
		else begin
			case(order_food_info.d_food_ID)
				FOOD1 : begin
					res_info_take.limit_num_orders <= res_ori_info.limit_num_orders;
					res_info_take.ser_FOOD1 <= res_ori_info.ser_FOOD1 + order_food_info.d_ser_food;
					res_info_take.ser_FOOD2 <= res_ori_info.ser_FOOD2;
					res_info_take.ser_FOOD3 <= res_ori_info.ser_FOOD3;
				end
				FOOD2 : begin
					res_info_take.limit_num_orders <= res_ori_info.limit_num_orders;
					res_info_take.ser_FOOD1 <= res_ori_info.ser_FOOD1 ;
					res_info_take.ser_FOOD2 <= res_ori_info.ser_FOOD2 + order_food_info.d_ser_food;
					res_info_take.ser_FOOD3 <= res_ori_info.ser_FOOD3;
				end
				FOOD3 : begin
					res_info_take.limit_num_orders <= res_ori_info.limit_num_orders;
					res_info_take.ser_FOOD1 <= res_ori_info.ser_FOOD1 ;
					res_info_take.ser_FOOD2 <= res_ori_info.ser_FOOD2 ;
					res_info_take.ser_FOOD3 <= res_ori_info.ser_FOOD3 + order_food_info.d_ser_food;
				end
			endcase
		end
	end
end

//deli_temp_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		deli_temp_info <= 'd0;
	else if(cs==ST_TAKE_READ && inf.C_out_valid)begin
		deli_temp_info <= {inf.C_data_r[39:32],inf.C_data_r[47:40],inf.C_data_r[55:48],inf.C_data_r[63:56]};
	end
end


always_comb begin
	if(flag_res_take) begin
		case(custom_take_info.food_ID)
			FOOD1 : begin
				if(res_info_take.ser_FOOD1 < custom_take_info.ser_food)
					flag_nofood = 1;
				else
					flag_nofood = 0;
			end
			FOOD2 : begin
				if(res_info_take.ser_FOOD2 < custom_take_info.ser_food)
					flag_nofood = 1;
				else
					flag_nofood = 0;
			end
			FOOD3 : begin
				if(res_info_take.ser_FOOD3 < custom_take_info.ser_food)
					flag_nofood = 1;
				else
					flag_nofood = 0;
			end
			default : flag_nofood = 0;
		endcase
	end
	else 
		flag_nofood = 0;
end

always_comb begin
	if(flag_res_take)begin
		if(deli_ori_info.ctm_info1!=0 && deli_ori_info.ctm_info2!=0) 
			flag_deli_busy = 1;
		else
			flag_deli_busy = 0;
	end
	else 
		flag_deli_busy = 0;
end

always_comb begin
	if(cs==ST_ORDER_READ)begin
		if(res_ori_info.limit_num_orders - res_ori_info.ser_FOOD1 - res_ori_info.ser_FOOD2 - res_ori_info.ser_FOOD3 < order_food_info.d_ser_food)
			flag_res_busy = 1;
		else
			flag_res_busy = 0; 
	end
	else 
		flag_res_busy = 0;
end


//res_ori_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		res_ori_info <= 'd0;
	else if(cs==ST_ACT && inf.C_out_valid)begin
		res_ori_info <= {inf.C_data_r[7:0],inf.C_data_r[15:8],inf.C_data_r[23:16],inf.C_data_r[31:24]};
	end
	else if(flag_needed && (act_r==Take) && (custom_take_res_id==curr_deli_id) )
		res_ori_info <= res_info_take;
	else if(flag_needed && (act_r==Order) )
		res_ori_info <= res_info_take;
end

/*
//res_order_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		res_order_info <= 'd0;
	else if(flag_order)begin
		if(flag_res_busy) begin
			res_order_info <= res_ori_info;
		end
		else begin
			case(order_food_info.d_food_ID)
				FOOD1 : begin
					res_order_info.limit_num_orders <= res_ori_info.limit_num_orders;
					res_order_info.ser_FOOD1 <= res_ori_info.ser_FOOD1 + order_food_info.d_ser_food;
					res_order_info.ser_FOOD2 <= res_ori_info.ser_FOOD2;
					res_order_info.ser_FOOD3 <= res_ori_info.ser_FOOD3;
				end
				FOOD2 : begin
					res_order_info.limit_num_orders <= res_ori_info.limit_num_orders;
					res_order_info.ser_FOOD1 <= res_ori_info.ser_FOOD1 ;
					res_order_info.ser_FOOD2 <= res_ori_info.ser_FOOD2 + order_food_info.d_ser_food;
					res_order_info.ser_FOOD3 <= res_ori_info.ser_FOOD3;
				end
				FOOD3 : begin
					res_order_info.limit_num_orders <= res_ori_info.limit_num_orders;
					res_order_info.ser_FOOD1 <= res_ori_info.ser_FOOD1 ;
					res_order_info.ser_FOOD2 <= res_ori_info.ser_FOOD2 ;
					res_order_info.ser_FOOD3 <= res_ori_info.ser_FOOD3 + order_food_info.d_ser_food;
				end
			endcase
		end
	end
end
*/

//flag_deliver
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_deliver <= 'd0;
	else if(cs==ST_DELIVER)begin
		flag_deliver <= 'd1;
	end
	else
		flag_deliver <= 'd0;
end

//flag_cancel
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_cancel <= 'd0;
	else if(cs==ST_CANCEL_READ)begin
		flag_cancel <= 'd1;
	end
	else
		flag_cancel <= 'd0;
end

//deli_ori_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		deli_ori_info <= 'd0;
	else if(cs==ST_ACT && inf.C_out_valid)begin
		deli_ori_info <= {inf.C_data_r[39:32],inf.C_data_r[47:40],inf.C_data_r[55:48],inf.C_data_r[63:56]};
	end
	else if(flag_needed && act_r==Take)begin
		deli_ori_info <= deli_aft_info;
	end
end

//deli_aft_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		deli_aft_info <= 'd0;
	else if(flag_res_take) begin
		if(flag_nofood) begin
			deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info1;
			deli_aft_info.ctm_info2 <= deli_ori_info.ctm_info2;
		end
		else if(deli_ori_info.ctm_info1 == 0) begin
			deli_aft_info.ctm_info1 <= custom_take_info;
			deli_aft_info.ctm_info2 <= 0;
		end
		else if(deli_ori_info.ctm_info1 != 0 && deli_ori_info.ctm_info2 == 0)begin
			if(custom_take_info.ctm_status>deli_ori_info.ctm_info1.ctm_status) begin
				deli_aft_info.ctm_info1 <= custom_take_info;
				deli_aft_info.ctm_info2 <= deli_ori_info.ctm_info1;
			end
			else begin
				deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info1;
				deli_aft_info.ctm_info2 <= custom_take_info;
			end
		end
		else begin
			deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info1;
			deli_aft_info.ctm_info2 <= deli_ori_info.ctm_info2;
		end
	end
	else if(cs==ST_DELIVER) begin
		if(deli_ori_info.ctm_info1 != 0 && deli_ori_info.ctm_info2 != 0)begin
			deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info2;
			deli_aft_info.ctm_info2 <= 0;
		end
		else begin
			deli_aft_info.ctm_info1 <= 0;
			deli_aft_info.ctm_info2 <= 0;
		end
	end
	else if(cs== ST_CANCEL_READ)begin
		if( (deli_ori_info.ctm_info1.res_ID==curr_res_id) && (deli_ori_info.ctm_info1.food_ID==order_food_info.d_food_ID) && (deli_ori_info.ctm_info2.res_ID==curr_res_id) && (deli_ori_info.ctm_info2.food_ID==order_food_info.d_food_ID)) begin
			deli_aft_info.ctm_info1 <= 0;
			deli_aft_info.ctm_info2 <= 0;
		end
		else if((deli_ori_info.ctm_info2.res_ID==curr_res_id) && (deli_ori_info.ctm_info2.food_ID==order_food_info.d_food_ID)) begin
			deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info1;
			deli_aft_info.ctm_info2 <= 0;
		end
		else if((deli_ori_info.ctm_info1.res_ID==curr_res_id) && (deli_ori_info.ctm_info1.food_ID==order_food_info.d_food_ID)) begin
			deli_aft_info.ctm_info1 <= deli_ori_info.ctm_info2;
			deli_aft_info.ctm_info2 <= 0;
		end
	end
end



//flag_wro_cancel
always_comb begin
	if(cs== ST_CANCEL_READ)begin
		if((deli_ori_info.ctm_info1==0) && (deli_ori_info.ctm_info2==0))
			flag_wro_cancel = 1;
		else
			flag_wro_cancel = 0;
	end
	else 
		flag_wro_cancel = 0;
end

//flag_wro_res
always_comb begin
	if(cs== ST_CANCEL_READ)begin
		if((deli_ori_info.ctm_info1!=0) && (deli_ori_info.ctm_info2!=0)) begin
			if((deli_ori_info.ctm_info1.res_ID != curr_res_id) && (deli_ori_info.ctm_info2.res_ID != curr_res_id))
				flag_wro_res = 1;
			else
				flag_wro_res = 0;
		end
		else if(deli_ori_info.ctm_info1!=0)begin
			if(deli_ori_info.ctm_info1.res_ID != curr_res_id)
				flag_wro_res = 1;
			else
				flag_wro_res = 0;
		end
		else begin
			flag_wro_res = 0;
		end
	end
	else 
		flag_wro_res = 0;
end

//flag_wro_food
always_comb begin
	if(cs== ST_CANCEL_READ)begin
		if( (deli_ori_info.ctm_info1.res_ID==curr_res_id) && (deli_ori_info.ctm_info2.res_ID==curr_res_id)) begin
			if((deli_ori_info.ctm_info1.food_ID != order_food_info.d_food_ID) && (deli_ori_info.ctm_info2.food_ID != order_food_info.d_food_ID))
				flag_wro_food = 1;
			else
				flag_wro_food = 0;
		end
		else if(deli_ori_info.ctm_info1.res_ID==curr_res_id) begin
			if((deli_ori_info.ctm_info1.food_ID != order_food_info.d_food_ID))
				flag_wro_food = 1;
			else
				flag_wro_food = 0;
		end
		else if(deli_ori_info.ctm_info2.res_ID==curr_res_id) begin
			if((deli_ori_info.ctm_info2.food_ID != order_food_info.d_food_ID))
				flag_wro_food = 1;
			else
				flag_wro_food = 0;
		end
		else 
			flag_wro_food = 0;
	end
	else 
		flag_wro_food = 0;
end


//flag_no_cus
always_comb begin
	if(cs==ST_DELIVER)begin
		if(deli_ori_info.ctm_info1 == 0)
			flag_no_cus = 1;
		else
			flag_no_cus = 0;
	end
	else 
		flag_no_cus = 0;
end

//custom_take_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		custom_take_info <= 'd0;
	else if(inf.cus_valid) begin
		custom_take_info <= inf.D.d_ctm_info[0];
	end
end

//custom_take_res_id
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		custom_take_res_id <= 'd0;
	else begin
		custom_take_res_id <= custom_take_info.res_ID;
	end
end

//order_food_info
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		order_food_info <= 8'd0;
	else if(inf.food_valid)
		order_food_info <= inf.D.d_food_ID_ser[0];
end

//flag_order
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_order <= 'd0;
	else if(flag_res_val && flag_food_val)begin
		flag_order <= 'd1;
	end
	else if(flag_needed&& flag_food_val)
		flag_order <= 'd1;
	else
		flag_order <= 'd0;
end

//flag_res_val
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_res_val <= 'd0;
	else if(ns==ST_ACT)begin
		if(inf.C_out_valid)
			flag_res_val <= 'd1;
	end
	else
		flag_res_val <= 'd0;
end

//flag_food_val
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		flag_food_val <= 'd0;
	else if(ns==ST_ACT)begin
		if(inf.food_valid)
			flag_food_val <= 'd1;
	end
	else
		flag_food_val <= 'd0;
end


//================================================================
//                           output
//================================================================

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_addr <= 'd0;
	else if(inf.id_valid)
		inf.C_addr 		<= inf.D.d_id[0];
	else if(inf.res_valid && act_r==Order)
		inf.C_addr 		<= inf.D.d_res_id[0];
	else if(ns== ST_TAKE_READ)
		inf.C_addr		<= custom_take_info.res_ID;
	else if(ns== ST_TAKE_WRITE_D || cs==ST_DELIVER || cs==ST_CANCEL_READ)
		inf.C_addr		<= curr_deli_id;
	else if(ns== ST_TAKE_WRITE_R)
		inf.C_addr		<= custom_take_info.res_ID;
	else if(ns==ST_ORDER_WRITE)
		inf.C_addr 		<= curr_res_id;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_data_w <= 'd0;
	else if(ns== ST_TAKE_WRITE_D || cs==ST_DELIVER)
		inf.C_data_w <= {deli_aft_info[7:0],deli_aft_info[15:8],deli_aft_info[23:16],deli_aft_info[31:24],res_ori_info[7:0],res_ori_info[15:8],res_ori_info[23:16],res_ori_info[31:24]};
	else if(ns== ST_TAKE_WRITE_R) begin
		if(custom_take_info.res_ID == curr_deli_id)
			inf.C_data_w <= {deli_aft_info[7:0],deli_aft_info[15:8],deli_aft_info[23:16],deli_aft_info[31:24],res_info_take[7:0],res_info_take[15:8],res_info_take[23:16],res_info_take[31:24]};
		else
			inf.C_data_w <= {deli_temp_info[7:0],deli_temp_info[15:8],deli_temp_info[23:16],deli_temp_info[31:24],res_info_take[7:0],res_info_take[15:8],res_info_take[23:16],res_info_take[31:24]};
    end
    else if(ns==ST_ORDER_WRITE) begin
    	inf.C_data_w <= {deli_ori_info[7:0],deli_ori_info[15:8],deli_ori_info[23:16],deli_ori_info[31:24],res_info_take[7:0],res_info_take[15:8],res_info_take[23:16],res_info_take[31:24]};
    end
    else if(cs==ST_CANCEL_READ) 
    	inf.C_data_w <= {deli_aft_info[7:0],deli_aft_info[15:8],deli_aft_info[23:16],deli_aft_info[31:24],res_ori_info[7:0],res_ori_info[15:8],res_ori_info[23:16],res_ori_info[31:24]};
    else 
    	inf.C_data_w <= 'd0;
end

//C_in_valid
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_in_valid <= 'd0;
	else if(ns==ST_ACT && inf.id_valid)
		inf.C_in_valid <= 'd1;
	else if(ns==ST_ACT && inf.res_valid && act_r==Order)
		inf.C_in_valid <= 'd1;
	else if(ns== ST_TAKE_READ && cs==ST_ACT )
		inf.C_in_valid <= 'd1;
	else if(ns== ST_TAKE_WRITE_D && cs==ST_TAKE_READ)
		inf.C_in_valid	<= 'd1;
	else if(ns== ST_TAKE_WRITE_R && cs==ST_TAKE_WRITE_D)
		inf.C_in_valid	<= 'd1;
	else if(cs==ST_DELIVER && !flag_deliver && !flag_no_cus)
		inf.C_in_valid	<= 'd1;
	else if(ns==ST_ORDER_WRITE && cs==ST_ORDER_READ)
		inf.C_in_valid	<= 'd1;
	else if(cs==ST_CANCEL_READ && !flag_cancel &&!flag_wro_res && !flag_wro_food && !flag_wro_cancel)
		inf.C_in_valid	<= 'd1;
    else 
    	inf.C_in_valid <= 'd0;
end

//C_r_wb 1:read dram,0:write dram
always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_r_wb <= 'd0;
	else if(ns== ST_TAKE_WRITE_D || ns== ST_TAKE_WRITE_R || cs==ST_DELIVER || ns==ST_ORDER_WRITE || cs==ST_CANCEL_READ)
		inf.C_r_wb	<= 'd0;
    else 
    	inf.C_r_wb <= 'd1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)	
		inf.out_valid <= 'd0;
    else if (ns==ST_OUTPUT) 
    	inf.out_valid <= 'd1;
	else
		inf.out_valid <= 'd0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.out_info <= 64'd0;
    else if(ns==ST_OUTPUT) begin
    	if(flag_nofood || flag_deli_busy || flag_no_cus || flag_res_busy|| flag_wro_cancel || flag_wro_res || flag_wro_food) 
    		inf.out_info <= 64'd0;
    	else begin
    		case (act_r)
    			Take 	: inf.out_info <= {deli_aft_info,res_info_take};
    			Deliver : inf.out_info <= {deli_aft_info,32'd0};
    			Order 	: inf.out_info <= {32'd0,res_info_take};
    			Cancel 	: inf.out_info <= {deli_aft_info,32'd0};
    			default : inf.out_info <= 64'd0;
    		endcase
    	end
    end
	else
		inf.out_info <= 64'd0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.complete <= 'd0;
    else if(flag_nofood || flag_deli_busy || flag_no_cus || flag_res_busy || flag_wro_cancel || flag_wro_res || flag_wro_food)
    	inf.complete <= 'd0;
    else 
    	inf.complete <= 'd1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.err_msg <= No_Err;
	else if(flag_deli_busy)
		inf.err_msg <= D_man_busy;
	else if(flag_nofood)
		inf.err_msg <= No_Food;
	else if(flag_no_cus)
		inf.err_msg <= No_customers;
	else if(flag_res_busy)
		inf.err_msg <= Res_busy;
	else if(flag_wro_cancel)
		inf.err_msg <= Wrong_cancel;
	else if(flag_wro_res)
		inf.err_msg <= Wrong_res_ID;
	else if(flag_wro_food)
		inf.err_msg <= Wrong_food_ID;
	else
		inf.err_msg <= No_Err;
end

endmodule
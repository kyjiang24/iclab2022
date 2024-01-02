`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================

parameter PATNUM = 433; //433 100%
integer seed = 3100122;

integer i,d; 
integer once_latency,total_latency;

//================================================================
//  logic
//================================================================
                                                                    
Action old_act,cur_act;
Delivery_man_id cur_deli_id;
Ctm_Info cur_cus_info,ctm_info_tmp;
Restaurant_id cur_res_id;
food_ID_servings cur_food_or,cur_food_c;

D_man_Info deli_man_info;

res_info cur_res_info;

Error_Msg patter_err;

logic pattern_complete;
logic[63:0] pattern_info;
//================================================================
//  initial_Dram
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM[(65536+0):((65536+256*8)-1)];


initial $readmemh(DRAM_p_r,golden_DRAM);
//================================================================
//  random
//================================================================

class rand_action;
    randc Action act;

    constraint range{
        act inside { Take, Deliver, Order, Cancel };
    }
endclass

/*
class rand_deliver_id;
    randc Delivery_man_id deli_id;
    
    constraint range{
        deli_id inside {[0:255]};
    }
endclass
*/

class rand_custom_info;
    randc Ctm_Info cus_info;

    constraint range{
        cus_info.ctm_status inside{Normal,VIP};
        cus_info.res_ID     inside{[0:255]};
        cus_info.food_ID    inside{FOOD1,FOOD2,FOOD3};
        cus_info.ser_food   inside{[1:15]};
    }
endclass

class rand_res_id;
    rand Restaurant_id res_id;

    constraint range{
        res_id inside {[0:255]};
    }
endclass

class rand_food;
    rand food_ID_servings food_info;

    constraint range{
        food_info.d_food_ID inside{ FOOD1, FOOD2, FOOD3 };
        food_info.d_ser_food inside{ [1:15] };
    }
endclass


//======================================
//              TASKS
//======================================

initial begin

    reset_task;

    for (i = 0 ; i < PATNUM ; i = i + 1) begin

        repeat($urandom_range(2,9)) @(negedge clk);

        input_task;

        wait_task;

        calculate_task;
        check_task;
        total_latency = total_latency + once_latency;
        //$display("\033[1;35m  pass %5d ,action= %10s ,err_msg :%10s\033[m",i,cur_act.name(),patter_err.name());
    end
    @(negedge clk);
    $finish;
end

task reset_task;
begin 
    inf.rst_n = 'd1;
    inf.D = 'dx;
    inf.act_valid = 'd0;
    inf.id_valid = 'd0;
    inf.cus_valid = 'd0;
    inf.res_valid = 'd0;
    inf.food_valid = 'd0;
    total_latency = 'd0;
    d = 'd0;
    #(10); inf.rst_n = 'd0;
    #(10); inf.rst_n = 'd1;
end
endtask

task input_task;
begin
    rand_act_task;
    repeat($urandom_range(1,5)) @(negedge clk);

    case(cur_act)
        Take : begin
            if( (old_act==Take && ($urandom_range(0,1)==1)) || old_act!==Take || i==0 ) begin
                rand_deli_task;
                repeat($urandom_range(1,5)) @(negedge clk);
            end
            rand_custom_task;
        end
        Deliver : begin
            rand_deli_task;
        end
        Order : begin
            if( (old_act==Order && ($urandom_range(0,1)==1)) || old_act!==Order || i==0 ) begin
                rand_resid_task;
                repeat($urandom_range(1,5)) @(negedge clk);
            end
            rand_order_food_task;
        end
        Cancel : begin
            rand_resid_task;

            repeat($urandom_range(1,5)) @(negedge clk);
            rand_cancel_food_task;

            repeat($urandom_range(1,5)) @(negedge clk);
            rand_deli_task;
        end
    endcase // cur_act
end
endtask

task rand_act_task; 
begin    
    rand_action randact = new();
    
    void'(randact.randomize());
    inf.act_valid = 1;
    old_act = cur_act;
    /*
    case(i)
        0 : cur_act = Cancel;
        1 : cur_act = Cancel;
        default : cur_act = randact.act;
    endcase
    */
    if(i<20) begin
        cur_act = Cancel;
    end
    else if(i<40) begin
        cur_act = Order;
    end
    else if(i>400 && i<425) begin
        cur_act = Take;
    end
    else begin
        cur_act = randact.act;
    end
    inf.D = cur_act;

    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 'dx;
end
endtask

task rand_deli_task;
begin
    //rand_deliver_id randdeli = new();

    //void'(randdeli.randomize());
    inf.id_valid = 1;

    if(i<20) begin
        cur_deli_id = 3;
    end
    else begin
        cur_deli_id = d;
        d = (d==255) ? 0 : d+1 ;
    end
    
    inf.D = cur_deli_id;

    @(negedge clk);
    inf.id_valid = 0;
    inf.D = 'dx;
end
endtask

task rand_custom_task;
begin
    rand_custom_info randcus = new();

    void'(randcus.randomize());
    inf.cus_valid = 1;

    cur_cus_info = randcus.cus_info;
    inf.D = cur_cus_info;

    @(negedge clk);
    inf.cus_valid = 0;
    inf.D = 'dx;
end
endtask

task rand_resid_task;
begin
    rand_res_id randres = new();

    inf.res_valid = 1;
    void'(randres.randomize());

    if(i<20) begin
        cur_res_id = 0;
    end
    else if(i<40) begin
        cur_res_id = 160;
    end
    else begin
        cur_res_id = randres.res_id;
    end
    //cur_res_id = randres.res_id;
    inf.D = cur_res_id;

    @(negedge clk);
    inf.res_valid = 0;
    inf.D = 'dx;
end
endtask 

task rand_order_food_task;
begin
    rand_food randfood_or = new();

    inf.food_valid = 1;
    void'(randfood_or.randomize());

    cur_food_or = randfood_or.food_info;
    inf.D = cur_food_or;

    @(negedge clk);
    inf.food_valid = 0;
    inf.D = 'dx;
end
endtask

task rand_cancel_food_task;
begin
    rand_food randfood_c = new();

    inf.food_valid = 1;
    void'(randfood_c.randomize());
    randfood_c.food_info.d_ser_food = 0;
    cur_food_c = randfood_c.food_info;
    inf.D = cur_food_c;

    @(negedge clk);
    inf.food_valid = 0;
    inf.D = 'dx;
end
endtask



//WAIT TASK
task wait_task; begin
    once_latency = 0;
    while (inf.out_valid !== 1)begin
        once_latency = once_latency + 1;
        @(negedge clk);
    end
end
endtask


//CAL TASK
task calculate_task;
begin
    case(cur_act)
        Take : begin

            deli_man_info.ctm_info1 = {golden_DRAM[(65536+cur_deli_id*8+4)],golden_DRAM[(65536+cur_deli_id*8+5)]};
            deli_man_info.ctm_info2 = {golden_DRAM[(65536+cur_deli_id*8+6)],golden_DRAM[(65536+cur_deli_id*8+7)]};

            cur_res_info.limit_num_orders = golden_DRAM[(65536+cur_cus_info.res_ID*8)  ];
            cur_res_info.ser_FOOD1        = golden_DRAM[(65536+cur_cus_info.res_ID*8+1)];
            cur_res_info.ser_FOOD2        = golden_DRAM[(65536+cur_cus_info.res_ID*8+2)];
            cur_res_info.ser_FOOD3        = golden_DRAM[(65536+cur_cus_info.res_ID*8+3)];
    
            // Delivery man busy
            if(deli_man_info.ctm_info2.ctm_status !== None) begin
                pattern_complete = 0;
                pattern_info = 0;
                patter_err = D_man_busy;    
            end
            // No food
            else if(cur_cus_info.food_ID == FOOD1 && (cur_res_info.ser_FOOD1<cur_cus_info.ser_food) ) begin
                pattern_complete = 0;
                pattern_info     = 0;
                patter_err  = No_Food;
            end
            else if(cur_cus_info.food_ID == FOOD2 && (cur_res_info.ser_FOOD2<cur_cus_info.ser_food) ) begin
                pattern_complete = 0;
                pattern_info     = 0;
                patter_err  = No_Food;
            end
            else if(cur_cus_info.food_ID == FOOD3 && (cur_res_info.ser_FOOD3<cur_cus_info.ser_food) ) begin
                pattern_complete = 0;
                pattern_info     = 0;
                patter_err  = No_Food;
            end
            // Correct
            else begin
                pattern_complete = 1;
                patter_err = No_Err;

                case(cur_cus_info.food_ID)
                    FOOD1 : cur_res_info.ser_FOOD1 = cur_res_info.ser_FOOD1 - cur_cus_info.ser_food;
                    FOOD2 : cur_res_info.ser_FOOD2 = cur_res_info.ser_FOOD2 - cur_cus_info.ser_food;
                    FOOD3 : cur_res_info.ser_FOOD3 = cur_res_info.ser_FOOD3 - cur_cus_info.ser_food;
                endcase

                if (deli_man_info.ctm_info1.ctm_status == None) begin
                    deli_man_info.ctm_info1 = cur_cus_info;
                    deli_man_info.ctm_info2 = 0;
                end
                else if( deli_man_info.ctm_info1.ctm_status==Normal && cur_cus_info.ctm_status==VIP)begin
                    ctm_info_tmp = deli_man_info.ctm_info1;
                    deli_man_info.ctm_info1 = cur_cus_info;
                    deli_man_info.ctm_info2 = ctm_info_tmp;
                end
                else begin
                    deli_man_info.ctm_info1 = deli_man_info.ctm_info1;
                    deli_man_info.ctm_info2 = cur_cus_info;
                end

                {golden_DRAM[ (65536+cur_deli_id*8+4) ], golden_DRAM[ (65536+cur_deli_id*8+5) ]} = deli_man_info.ctm_info1;
                {golden_DRAM[ (65536+cur_deli_id*8+6) ], golden_DRAM[ (65536+cur_deli_id*8+7) ]} = deli_man_info.ctm_info2;


                golden_DRAM[ (65536+cur_cus_info.res_ID*8)   ] = cur_res_info.limit_num_orders;
                golden_DRAM[ (65536+cur_cus_info.res_ID*8+1) ] = cur_res_info.ser_FOOD1;
                golden_DRAM[ (65536+cur_cus_info.res_ID*8+2) ] = cur_res_info.ser_FOOD2;
                golden_DRAM[ (65536+cur_cus_info.res_ID*8+3) ] = cur_res_info.ser_FOOD3;

                pattern_info = {deli_man_info, cur_res_info};
            end
        end
        Deliver : begin

            deli_man_info.ctm_info1 = {golden_DRAM[(65536+cur_deli_id*8+4)],golden_DRAM[(65536+cur_deli_id*8+5)]};
            deli_man_info.ctm_info2 = {golden_DRAM[(65536+cur_deli_id*8+6)],golden_DRAM[(65536+cur_deli_id*8+7)]};

            // No customers
            if(deli_man_info.ctm_info1 === 0) begin
                pattern_complete = 'd0;
                pattern_info = 'd0;
                patter_err = No_customers;
            end
            else begin
                pattern_complete = 'd1;
                patter_err = 0;

                deli_man_info.ctm_info1 = deli_man_info.ctm_info2;
                deli_man_info.ctm_info2 = 0;
                pattern_info = {deli_man_info, 32'd0};

                {golden_DRAM[(65536+cur_deli_id*8+4)], golden_DRAM[(65536+cur_deli_id*8+5)]} = deli_man_info.ctm_info1;
                {golden_DRAM[(65536+cur_deli_id*8+6)], golden_DRAM[(65536+cur_deli_id*8+7)]} = deli_man_info.ctm_info2;
            end
        end
        Order : begin

            cur_res_info.limit_num_orders = golden_DRAM[(65536+cur_res_id*8)  ];
            cur_res_info.ser_FOOD1        = golden_DRAM[(65536+cur_res_id*8+1)];
            cur_res_info.ser_FOOD2        = golden_DRAM[(65536+cur_res_id*8+2)];
            cur_res_info.ser_FOOD3        = golden_DRAM[(65536+cur_res_id*8+3)];
            // Restaurant busy
            if( (cur_res_info.limit_num_orders-cur_res_info.ser_FOOD1-cur_res_info.ser_FOOD2-cur_res_info.ser_FOOD3) < cur_food_or.d_ser_food) begin
                pattern_complete = 'd0;             
                pattern_info = 'd0;
                patter_err = Res_busy;
            end
            else begin
                pattern_complete = 'd1;
                patter_err = 'd0;
                
                case (cur_food_or.d_food_ID)
                    FOOD1 : begin
                        cur_res_info.ser_FOOD1 = cur_res_info.ser_FOOD1 + cur_food_or.d_ser_food;
                        golden_DRAM[(65536+cur_res_id*8+1)] = cur_res_info.ser_FOOD1;
                    end
                    FOOD2 : begin
                        cur_res_info.ser_FOOD2 = cur_res_info.ser_FOOD2 + cur_food_or.d_ser_food;
                        golden_DRAM[(65536+cur_res_id*8+2)] = cur_res_info.ser_FOOD2;
                    end
                    FOOD3 : begin
                        cur_res_info.ser_FOOD3 = cur_res_info.ser_FOOD3 + cur_food_or.d_ser_food;
                        golden_DRAM[(65536+cur_res_id*8+3)] = cur_res_info.ser_FOOD3;
                    end
                endcase

                pattern_info = {32'd0, cur_res_info};
            end
        end
        Cancel : begin

            deli_man_info.ctm_info1 = {golden_DRAM[(65536+cur_deli_id*8+4)],golden_DRAM[(65536+cur_deli_id*8+5)]};
            deli_man_info.ctm_info2 = {golden_DRAM[(65536+cur_deli_id*8+6)],golden_DRAM[(65536+cur_deli_id*8+7)]};

            cur_res_info.limit_num_orders = golden_DRAM[(65536+cur_res_id*8)  ];
            cur_res_info.ser_FOOD1        = golden_DRAM[(65536+cur_res_id*8+1)];
            cur_res_info.ser_FOOD2        = golden_DRAM[(65536+cur_res_id*8+2)];
            cur_res_info.ser_FOOD3        = golden_DRAM[(65536+cur_res_id*8+3)];

            if((deli_man_info.ctm_info1.res_ID === cur_res_id && deli_man_info.ctm_info1.food_ID === cur_food_c.d_food_ID) || (deli_man_info.ctm_info2.res_ID === cur_res_id && deli_man_info.ctm_info2.food_ID === cur_food_c.d_food_ID)) begin
                pattern_complete = 'd1;
                patter_err = No_Err;
                
                //customer 1
                if(deli_man_info.ctm_info1.res_ID === cur_res_id && deli_man_info.ctm_info1.food_ID === cur_food_c.d_food_ID) begin
                    deli_man_info.ctm_info1 = 'd0;
                end
                //customer 2
                if(deli_man_info.ctm_info2.res_ID === cur_res_id && deli_man_info.ctm_info2.food_ID === cur_food_c.d_food_ID) begin
                    deli_man_info.ctm_info2 = 'd0;
                end

                if(deli_man_info.ctm_info1 === 0 && deli_man_info.ctm_info2!==0) begin
                    deli_man_info.ctm_info1 = deli_man_info.ctm_info2;
                    deli_man_info.ctm_info2 = 'd0;
                end
                
                pattern_info = {deli_man_info, 32'd0};

                {golden_DRAM[(65536+cur_deli_id*8+4)], golden_DRAM[(65536+cur_deli_id*8+5)]} = deli_man_info.ctm_info1;
                {golden_DRAM[(65536+cur_deli_id*8+6)], golden_DRAM[(65536+cur_deli_id*8+7)]} = deli_man_info.ctm_info2;
            end
            // Wrong cancel
            else if(deli_man_info.ctm_info1 === 0) begin
                pattern_complete = 'd0;
                pattern_info = 'd0;
                patter_err  = Wrong_cancel;
            end
            //wrong res_id
            else if(deli_man_info.ctm_info1.res_ID !== cur_res_id && deli_man_info.ctm_info2.res_ID !== cur_res_id) begin
                // Wrong restaurant Id
                pattern_complete = 'd0;
                pattern_info = 'd0;
                patter_err  = Wrong_res_ID;
            end
            //wrong food_id
            else if(deli_man_info.ctm_info1.res_ID === cur_res_id && deli_man_info.ctm_info2.res_ID === cur_res_id)begin
                if( (deli_man_info.ctm_info1.food_ID !== cur_food_c.d_food_ID) && (deli_man_info.ctm_info2.food_ID !== cur_food_c.d_food_ID) ) begin
                    pattern_complete = 'd0;
                    pattern_info = 'd0;
                    patter_err  = Wrong_food_ID;
                end
            end
            else if(deli_man_info.ctm_info1.res_ID === cur_res_id)begin
                if(deli_man_info.ctm_info1.food_ID !== cur_food_c.d_food_ID) begin
                    pattern_complete = 'd0;
                    pattern_info = 'd0;
                    patter_err  = Wrong_food_ID;
                end
            end
            else if(deli_man_info.ctm_info2.res_ID === cur_res_id)begin
                if(deli_man_info.ctm_info2.food_ID !== cur_food_c.d_food_ID) begin
                    pattern_complete = 'd0;
                    pattern_info = 'd0;
                    patter_err  = Wrong_food_ID;
                end
            end
        end
    endcase
end
endtask 

task check_task;
begin
    if ( inf.complete !== pattern_complete || inf.out_info !== pattern_info || inf.err_msg !== patter_err ) begin
        $display("Wrong Answer");
        //$display("pattern_info:%16h , pattern_complete: %b ,patter_err: %10s",pattern_info,pattern_complete,patter_err.name());
        //$display("cur_info:%16h , cur_complete: %b ,cur_err: %10s",inf.out_info,inf.complete,inf.err_msg.name());
        $finish;
    end
    
end
endtask

endprogram
`timescale 1ns/1ns
`include "definition_new.v"
`include "design_test.v"

//defines
`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 76

module tb();
        localparam W = `WIDTH;
        localparam N = `CMD_WIDTH;
        parameter stimulus_width = 19 + 2*W + N + 2*W; //(feature_id+cin+ce+inp_valid+mode+exp_g+exp_e+exp_l+exp_err)+(opa+opb)+cmd+(exp_result)
        parameter response_width = stimulus_width + 2*W + 6;
        reg [stimulus_width - 1 : 0] current_test_case = 0; //a reg to store the current testcase
        reg [stimulus_width - 1 : 0] stimulus_mem [0 : `no_of_testcase - 1]; //to store all testcases so they can be read
        reg [response_width - 1:0] response_packet;

        //ALL inputs regs which are to read from stimulus_mem
        integer i, j;
        reg clk, rst, ce, mode, cin;
        reg [1 : 0] inp_valid;
        reg [W - 1 : 0] opa, opb;
        reg [N - 1 : 0] cmd;
        reg [7 : 0] feature_id;

        reg [2*W - 1 : 0] exp_result;
        reg exp_cout, exp_oflow, exp_err;
        reg [2:0] exp_egl;

        //All output wires from dut
        wire [2*W - 1 : 0] res;
        wire [2 : 0] egl;
        wire oflow, cout, err;
        wire [2*W + 6 - 1 : 0] expected_data;
        reg [2*W + 6 - 1 : 0]exact_data;

        //declaring event
        event fetch_stimulus;
        //to read from stimulus.txt
        task read_stimulus();
                begin
                        #10 $readmemb("stimulus.txt", stimulus_mem);
                end
        endtask

        //dut instantiation
        alu #(W, N) dut (.clk(clk), .rst(rst), .inp_valid(inp_valid), .mode(mode), .cin(cin), .ce(ce), .cmd(cmd), .opa(opa), .opb(opb), .res(res), .oflow(oflow), .cout(cout), .g(egl[1]), .l(egl[0]), .e(egl[2]), .err(err));


        //STIMULUS GENERATOR
        integer stim_mem_ptr = 0, stim_stimulus_mem_ptr = 0, fid = 0, pointer = 0;
        always@(fetch_stimulus)begin
                current_test_case = stimulus_mem[stim_mem_ptr];
                $display("stimulus_mem data = %b \n",stimulus_mem[stim_mem_ptr]);
                $display("currrent test case  = %b", current_test_case);
                stim_mem_ptr = stim_mem_ptr + 1;
        end

        //clock
        initial begin
                clk = 0;
                 forever #60 clk = ~clk;
        end


        //drive the inputs at clock edge recieved from current_test_case which in turn it recieves from stimulus_mem
        task driver();
                begin
                        ->fetch_stimulus;
                        @(posedge clk);
                        feature_id = current_test_case[(stimulus_width - 1) -: 8];
                        opa = current_test_case[(stimulus_width - 9) -: W];
                        opb = current_test_case[(stimulus_width - 9 - W) -: W];
                        cmd = current_test_case[(stimulus_width - 9 - 2*W) -: N];
                        cin = current_test_case[(stimulus_width - 9 - 2*W - N)];
                        ce = current_test_case[(stimulus_width - 10 - 2*W - N)];
                        inp_valid = current_test_case[(stimulus_width - 11 - 2*W - N) -: 2];
                        mode = current_test_case[(stimulus_width - 13 - 2*W - N)];
                        exp_result = current_test_case[(stimulus_width - 14 - 2*W - N) -: 2*W];
                        exp_cout = current_test_case[(stimulus_width - 14 - 4*W - N)];
                        exp_oflow = current_test_case[(stimulus_width - 15 - 4*W - N)];
                        exp_egl = current_test_case[(stimulus_width - 16 - 4*W - N) -: 3];
                        exp_err = current_test_case[(stimulus_width - 19 - 4*W - N)];
                        $display("At time %0t, feature_id = %b | opa = %b | opb = %b | cmd = %b | ce = %b | inp_valid = %b | mode = %b | exp_result = %b | exp_cout = %b | exp_oflow = %b | egl = %b | err = %b", $time, feature_id, opa, opb, cmd, ce, inp_valid, mode, exp_result, exp_cout, exp_oflow, exp_egl, exp_err);
                end
        endtask
        //DUT reset task
        task dut_reset();
                begin
                        rst = 0;
                        ce = 1;
                        #10 rst = 1;
                        #20 rst = 0;
                end
        endtask

        reg [31:0] count;
        //Global Initialization
        task global_init();
                begin
                        current_test_case = 55'b0;
                        response_packet = 80'b0;
                        stim_mem_ptr = 0;
                        count = 0;
                end
        endtask

        //Monitor task: capture DUT outputs
        task monitor();
                begin
                        repeat(5)@(posedge clk);
                        #5 response_packet[stimulus_width - 1 : 0] = current_test_case;
                        response_packet[stimulus_width] = err;
                        response_packet[stimulus_width + 3 : stimulus_width + 1] = egl;
                        response_packet[stimulus_width + 4] = oflow;
                        response_packet[stimulus_width + 5] = cout;
                        response_packet[stimulus_width + 5 + 2*W: stimulus_width + 6] = res;
                        $display("Response Packet = %b\n", response_packet);
                        $display("Monitor task at time %0t | res = %b | cout = %b | egl = %b | oflow = %b | err = %b", $time, res, cout, egl, oflow, err);
                        exact_data = {res, cout, oflow,egl, err};
                end
        endtask
        assign expected_data = {exp_result, exp_cout,exp_oflow, exp_egl,exp_err};

        //Scoreboard task to check the dut output with expected output
        task score_board();

                begin

                        $display("Expected data = %b | Response data = %b", expected_data, exact_data);
                        if(expected_data === exact_data)
                                $display("PASSED");
                        else begin
                                $display("FAILED");
                                count = count + 1;
                        end
                        $display("No of testcases failed = %0d\n", count);
                        $display("\n----------------THE END-------------------\n");
                end
        endtask

        initial begin
                #10;
                global_init();
                dut_reset();
                read_stimulus();
                for(j=0; j <= `no_of_testcase - 1; j = j + 1)begin
                        fork
                                driver();
                                monitor();
                        join
                        score_board();
                end
                #300 $finish;
        end
endmodule
